class CaptureManager

  attr_accessor :session, :orientation, :deviceConnectedObserver, :deviceDisconnectedObserver, :stillImageOutput, :videoInput, :audioInput, :delegate, :recorder, :backgroundRecordingID, :captureCancelled

  def init
    super

    weakSelf = WeakRef.new(self)

    @captureCancelled = false

    @deviceConnectedObserver = App.notification_center.observe AVCaptureDeviceWasConnectedNotification do |notification|
      device = notification.object
      
      sessionHasDeviceWithMatchingMediaType = false
      deviceMediaType = nil
      if device.hasMediaType(AVMediaTypeAudio)
        deviceMediaType = AVMediaTypeAudio
      elsif device.hasMediaType(AVMediaTypeVideo)
        deviceMediaType = AVMediaTypeVideo
      end
      
      unless deviceMediaType.nil?
        for input in @session.inputs
          if input.device.hasMediaType(deviceMediaType)
            sessionHasDeviceWithMatchingMediaType = true
            break
          end
        end
        
        unless sessionHasDeviceWithMatchingMediaType
          error_ptr = Pointer.new(:object)
          input = AVCaptureDeviceInput.deviceInputWithDevice(device, error:error_ptr)
          if @session.canAddInput(input)
            @session.addInput(input)
          end
        end       
      end
            
      if delegate.respondsToSelector('captureManagerDeviceConfigurationChanged:')
        delegate.captureManagerDeviceConfigurationChanged(self)
      end 
    end

    @deviceDisconnectedObserver = App.notification_center.observe AVCaptureDeviceWasDisconnectedNotification do |notification|
      device = notification.object
      
      if device.hasMediaType(AVMediaTypeAudio)
        @session.removeInput(weakSelf, audioInput)
        weakSelf.setAudioInput(nil)
      elsif device.hasMediaType(AVMediaTypeVideo)
        @session.removeInput(weakSelf, videoInput)
        weakSelf.setVideoInput(nil)
      end
      
      if delegate.respondsToSelector('captureManagerDeviceConfigurationChanged:')
        delegate.captureManagerDeviceConfigurationChanged(self)
      end
    end

    @orientationChangedObserver = App.notification_center.observe UIDeviceOrientationDidChangeNotification do |notification|
      deviceOrientationDidChange
    end

    @orientation = AVCaptureVideoOrientationPortrait

    return self
  end

  def setupSession
    success = false
    
    # Set torch and flash mode to auto
    if backFacingCamera.hasFlash
      if backFacingCamera.lockForConfiguration(nil)
        if backFacingCamera.isFlashModeSupported(AVCaptureFlashModeAuto)
          backFacingCamera.flashMode = AVCaptureFlashModeAuto
        end
        backFacingCamera.unlockForConfiguration
      end
    end
    if backFacingCamera.hasTorch
      if backFacingCamera.lockForConfiguration(nil)
        if backFacingCamera.isTorchModeSupported(AVCaptureTorchModeAuto)
          backFacingCamera.torchMode = AVCaptureTorchModeAuto
        end
        backFacingCamera.unlockForConfiguration
      end
    end
    
    # Init the device inputs
    newVideoInput = AVCaptureDeviceInput.alloc.initWithDevice(backFacingCamera, error:nil)
    newAudioInput = AVCaptureDeviceInput.alloc.initWithDevice(audioDevice, error:nil)
  
    # Setup the still image file output
    newStillImageOutput = AVCaptureStillImageOutput.new
    outputSettings = {AVVideoCodecKey => AVVideoCodecJPEG}

    newStillImageOutput.outputSettings = outputSettings
    
    # Create session (use default AVCaptureSessionPresetHigh)
    newCaptureSession = AVCaptureSession.new
    
    # Add inputs and output to the capture session
    if newCaptureSession.canAddInput(newVideoInput)
      newCaptureSession.addInput(newVideoInput)
    end
    if newCaptureSession.canAddInput(newAudioInput)
      newCaptureSession.addInput(newAudioInput)
    end
    if newCaptureSession.canAddOutput(newStillImageOutput)
      newCaptureSession.addOutput(newStillImageOutput)
    end
    
    @stillImageOutput = newStillImageOutput
    @videoInput = newVideoInput
    @audioInput = newAudioInput
    @session = newCaptureSession
      
    # Set up the movie file output
    outputFileURL = tempFileURL
    newRecorder = CamRecorder.alloc.initWithSession(@session, outputFileURL:outputFileURL)
    newRecorder.delegate = self
    
    # Send an error to the delegate if video recording is unavailable
    if !newRecorder.recordsVideo and newRecorder.recordsAudio
      localizedDescription = NSLocalizedString("Video recording unavailable", "Video recording unavailable description")
      localizedFailureReason = NSLocalizedString("Movies recorded on this device will only contain audio. They will be accessible through iTunes file sharing.", "Video recording unavailable failure reason")
      errorDict = {NSLocalizedDescriptionKey => localizedDescription, NSLocalizedFailureReasonErrorKey => localizedFailureReason}

      noVideoError = NSError.errorWithDomain("Cam", code:0, userInfo:errorDict)
      if @delegate.respondsToSelector('captureManager:didFailWithError:')
        @delegate.captureManager(self, didFailWithError:noVideoError)
      end
    end
    
    @recorder = newRecorder
    success = true

    return success
  end

  def startRecording
    if UIDevice.currentDevice.isMultitaskingSupported
      @backgroundRecordingID = UIApplication.sharedApplication.beginBackgroundTaskWithExpirationHandler(nil)
    end
    removeFile(@recorder.outputFileURL)
    @recorder.startRecordingWithOrientation(@orientation)
  end

  def stopRecording
    @recorder.stopRecording
  end

  def captureStillImage
    stillImageConnection = CamUtilities.connectionWithMediaType(AVMediaTypeVideo, fromConnections:@stillImageOutput.connections)
    stillImageConnection.setVideoOrientation(@orientation) if stillImageConnection.isVideoOrientationSupported and @orientation  
    
    error_ptr = Pointer.new(:object)
    @stillImageOutput.captureStillImageAsynchronouslyFromConnection(stillImageConnection,
                                                         completionHandler:lambda do |imageDataSampleBuffer, error_ptr|
      unless error_ptr
        unless imageDataSampleBuffer.nil?
          imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
          image = UIImage.alloc.initWithData(imageData)
          @library = ALAssetsLibrary.new unless @library
          @library.writeImageToSavedPhotosAlbum(image.CGImage, orientation:image.imageOrientation, completionBlock:nil)
        end

        if @delegate.respondsToSelector('captureManagerStillImageCaptured:')
          @delegate.captureManagerStillImageCaptured(image) if image
        end
      else
        Logger.error("captureStillImage Error: #{error_ptr}")
      end
    end)
  end

  def toggleCamera
    success = false
    
    if cameraCount > 1
      position = @videoInput.device.position
      
      error_ptr = Pointer.new(:object)
      if position == AVCaptureDevicePositionBack
        newVideoInput = AVCaptureDeviceInput.alloc.initWithDevice(frontFacingCamera, error:error_ptr)
      elsif position == AVCaptureDevicePositionFront
        newVideoInput = AVCaptureDeviceInput.alloc.initWithDevice(backFacingCamera, error:error_ptr)
      else
        return success
      end
      
      if newVideoInput
        @session.beginConfiguration
        @session.removeInput(@videoInput)
        if @session.canAddInput(newVideoInput)
          @session.addInput(newVideoInput)
          @videoInput = newVideoInput
        else
          @session.addInput(@videoInput)
        end
        @session.commitConfiguration
        success = true
      elsif error_ptr
        if @delegate.respondsToSelector('captureManager:didFailWithError:')
          @delegate.captureManager(self, didFailWithError:error_ptr)
        end
      end
    end
    return success
  end

  def cameraCount
    return AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo).count
  end

  def micCount
    return AVCaptureDevice.devicesWithMediaType(AVMediaTypeAudio).count
  end

  # Perform an auto focus at the specified point. The focus mode will automatically change to locked once the auto focus is complete.
  def autoFocusAtPoint(point)
    device = videoInput.device
    if device.isFocusPointOfInterestSupported and device.isFocusModeSupported(AVCaptureFocusModeAutoFocus)
      error_ptr = Pointer.new(:object)
      if device.lockForConfiguration(error_ptr)
        device.focusPointOfInterest = point
        device.focusMode = AVCaptureFocusModeAutoFocus
        device.unlockForConfiguration
      else
        if @delegate.respondsToSelector('captureManager:didFailWithError:')
          @delegate.captureManager(self, didFailWithError:error_ptr)
        end
      end        
    end
  end

  # Switch to continuous auto focus mode at the specified point
  def continuousFocusAtPoint(point)
    device = videoInput.device
    if device.isFocusPointOfInterestSupported and device.isFocusModeSupported(AVCaptureFocusModeContinuousAutoFocus)
      error_ptr = Pointer.new(:object)
      if device.lockForConfiguration(error_ptr)
        device.focusPointOfInterest = point
        device.focusMode = AVCaptureFocusModeContinuousAutoFocus
        device.unlockForConfiguration
      else
        if @delegate.respondsToSelector('captureManager:didFailWithError:')
          @delegate.captureManager(self, didFailWithError:error_ptr)
        end
      end        
    end
  end

    # Perform an auto focus at the specified point. The focus mode will automatically change to locked once the auto focus is complete.
  def autoExposureAtPoint(point)
    device = videoInput.device
    if device.isExposurePointOfInterestSupported and device.isExposureModeSupported(AVCaptureExposureModeAutoExposure)
      error_ptr = Pointer.new(:object)
      if device.lockForConfiguration(error_ptr)
        device.exposurePointOfInterest = point
        device.exposureMode = AVCaptureExposureModeAutoExposure
        device.unlockForConfiguration
      else
        if @delegate.respondsToSelector('captureManager:didFailWithError:')
          @delegate.captureManager(self, didFailWithError:error_ptr)
        end
      end        
    end
  end

  # Switch to continuous auto exposure mode at the specified point
  def continuousExposureAtPoint(point)
    device = videoInput.device
    if device.isExposurePointOfInterestSupported and device.isExposureModeSupported(AVCaptureExposureModeContinuousAutoExposure)
      error_ptr = Pointer.new(:object)
      if device.lockForConfiguration(error_ptr)
        device.exposurePointOfInterest = point
        device.exposureMode = AVCaptureExposureModeContinuousAutoExposure
        device.unlockForConfiguration
      else
        if @delegate.respondsToSelector('captureManager:didFailWithError:')
          @delegate.captureManager(self, didFailWithError:error_ptr)
        end
      end        
    end
  end

  # Keep track of current device orientation so it can be applied to movie recordings and still image captures
  def deviceOrientationDidChange
    deviceOrientation = UIDevice.currentDevice.orientation
      
    if deviceOrientation == UIDeviceOrientationPortrait
      @orientation = AVCaptureVideoOrientationPortrait
    elsif (deviceOrientation == UIDeviceOrientationPortraitUpsideDown)
      @orientation = AVCaptureVideoOrientationPortraitUpsideDown
    
    # AVCapture and UIDevice have opposite meanings for landscape left and right (AVCapture orientation is the same as UIInterfaceOrientation)
    elsif deviceOrientation == UIDeviceOrientationLandscapeLeft
      @orientation = AVCaptureVideoOrientationLandscapeRight
    elsif deviceOrientation == UIDeviceOrientationLandscapeRight
      @orientation = AVCaptureVideoOrientationLandscapeLeft
    end
    
    # Ignore device orientations for which there is no corresponding still image orientation (e.g. UIDeviceOrientationFaceUp)
  end

  # Find a camera with the specificed AVCaptureDevicePosition, returning nil if one is not found
  def cameraWithPosition(position)
    devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
    for device in devices
      if device.position == position
        return device
      end
    end
    return nil
  end

  # Find a front facing camera, returning nil if one is not found
  def frontFacingCamera
    return cameraWithPosition(AVCaptureDevicePositionFront)
  end

  # Find a back facing camera, returning nil if one is not found
  def backFacingCamera
    return cameraWithPosition(AVCaptureDevicePositionBack)
  end

  # Find and return an audio device, returning nil if one is not found
  def audioDevice
    devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeAudio)
    if devices.count > 0
      return devices[0]
    end
    return nil
  end

  def tempFileURL
    return NSURL.fileURLWithPath("#{NSTemporaryDirectory()}output.mov")
  end

  def removeFile(fileURL)
    filePath = fileURL.path
    fileManager = NSFileManager.defaultManager
    if fileManager.fileExistsAtPath(filePath)
      error_ptr = Pointer.new(:object)
      if fileManager.removeItemAtPath(filePath, error:error_ptr) == false
        if @delegate.respondsToSelector('captureManager:didFailWithError:')
          @delegate.captureManager(self, didFailWithError:error_ptr)
        end            
      end
    end
  end

  def copyFileToDocuments(fileURL)
    documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true)[0]
    dateFormatter = NSDateFormatter.new
    dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
    destinationPath = documentsDirectory.stringByAppendingFormat("/output_#{dateFormatter.stringFromDate(NSDate.date)}.mov")
    error_ptr = Pointer.new(:object)
    if !NSFileManager.defaultManager.copyItemAtURL(fileURL, toURL:NSURL.fileURLWithPath(destinationPath), error:error_ptr)
      if @delegate.respondsToSelector('captureManager:didFailWithError:')
        @delegate.captureManager(self, didFailWithError:error_ptr)
      end
    end
  end

  # delegate methods

  def recorderRecordingDidBegin(recorder)
    if @delegate.respondsToSelector('captureManagerRecordingBegan:')
      @delegate.captureManagerRecordingBegan(self)
    end
  end

  def recorder(recorder, recordingDidFinishToOutputFileURL:outputFileURL, error:error)
    unless @captureCancelled
      if @recorder.recordsAudio and !@recorder.recordsVideo
        # If the file was created on a device that doesn't support video recording, it can't be saved to the assets 
        # library. Instead, save it in the app's Documents directory, whence it can be copied from the device via
        # iTunes file sharing.
        copyFileToDocuments(outputFileURL)

        if UIDevice.currentDevice.isMultitaskingSupported
          UIApplication.sharedApplication.endBackgroundTask(@backgroundRecordingID)
        end   

        if @delegate.respondsToSelector('captureManagerRecordingFinished:')
          @delegate.captureManagerRecordingFinished(self)
        end
      else 
        library = ALAssetsLibrary.new
        library.writeVideoAtPathToSavedPhotosAlbum(outputFileURL, completionBlock:lambda do |assetURL, error|
          if error
            if @delegate.respondsToSelector('captureManager:didFailWithError:')
              @delegate.captureManager(self, didFailWithError:error)
            end                     
          end
          
          if UIDevice.currentDevice.isMultitaskingSupported
            UIApplication.sharedApplication.endBackgroundTask(@backgroundRecordingID)
          end
          
          if @delegate.respondsToSelector('captureManagerRecordingFinished:')
            @delegate.captureManagerRecordingFinished(assetURL)
          end
        end)
      end
    end
  end

  def dealloc
    App.notification_center.unobserve @deviceConnectedObserver
    App.notification_center.unobserve @deviceDisconnectedObserver
    App.notification_center.unobserve @orientationChangedObserver
    super
  end
end