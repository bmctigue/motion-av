class CamViewController < UIViewController

  include BW::KVO
  include CamButtons

  KPhoto = 0

  KCameraButtonWidth = 88.0
  KVideoButtonWidth = 58.0
  KbuttonHeight = 44.0
  KFocusModeLabelHeight = 20.0

  if Device.screen.height == 568.0
    KbuttonBackgroundHeight = 92.0
  else
    KbuttonBackgroundHeight = 54.0
  end

  attr_accessor :captureManager, :cameraToggleButton, :videoButton, :stillButton, :focusModeLabel, :videoPreviewView, :captureVideoPreviewLayer

  def self.sharedInstance
    Dispatch.once { 
      @instance = self.new unless @instance
    }
    @instance
  end

  def viewDidLoad
    super

    self.navigationItem.title = 'Camera'
    self.view.backgroundColor = :black.uicolor

    unless @captureManager
      @captureManager = CaptureManager.alloc.init
      
      @captureManager.delegate = self

      if @captureManager.setupSession
        # Create video preview layer and add it to the UI
        @videoPreviewView = UIView.alloc.initWithFrame([[0,0],[App.frame.size.width, App.frame.size.height - KbuttonBackgroundHeight - 44.0]])
        @captureVideoPreviewLayer = AVCaptureVideoPreviewLayer.alloc.initWithSession(@captureManager.session)
        viewLayer = @videoPreviewView.layer
        viewLayer.masksToBounds = true
         
        @captureVideoPreviewLayer.frame = @videoPreviewView.bounds
        
        if @captureVideoPreviewLayer.connection.isVideoOrientationSupported
          @captureVideoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait
        end
        
        @captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        @captureManager.session.sessionPreset = AVCaptureSessionPresetMedium if @captureManager.session.canSetSessionPreset(AVCaptureSessionPresetMedium)

        viewLayer.addSublayer(@captureVideoPreviewLayer)
        
        # Start the session. This is done asychronously since -startRunning doesn't return until the session is running.
        Dispatch::Queue.main.async do
          @captureManager.session.startRunning
        end
              
        # Add a single tap gesture to focus on the point tapped, then lock focus
        @videoPreviewView.on_tap(1) do |gesture|
          gesture.delegate = self
          tapToAutoFocus(gesture)
        end

        # Add a double tap gesture to reset the focus mode to continuous auto focus
        @videoPreviewView.on_tap(2) do |gesture|
          gesture.delegate = self
          tapToContinouslyAutoFocus(gesture)
        end

        @captureManager.continuousFocusAtPoint(CGPointMake(0.5,0.5))

        # Create the focus mode UI overlay
        @focusModeLabel = UILabel.alloc.initWithFrame([[10,App.frame.size.height - KbuttonBackgroundHeight - KFocusModeLabelHeight - 4.0 - 44.0],[(App.frame.size.width - 10.0)/2,KFocusModeLabelHeight]])
        @focusModeLabel.backgroundColor = :clear.uicolor
        @focusModeLabel.textColor = :white.uicolor
        @focusModeLabel.alpha = 0.5
        initialFocusMode = @captureManager.videoInput.device.focusMode
        @focusModeLabel.text = "focus: #{stringForFocusMode(initialFocusMode)}"
        @videoPreviewView.addSubview(@focusModeLabel)
        observe(captureManager.videoInput.device, :focusMode) do |old_value, new_value|
          @focusModeLabel.text = "focus: #{stringForFocusMode(new_value)}"
        end

        # watch for changes to the focus, update the focus box when focusing stops
        if @captureManager.videoInput.device.isFocusPointOfInterestSupported
          observe(@captureManager.videoInput.device, :adjustingFocus) do |old_value, new_value|
            if new_value == 0
              ratio = @videoPreviewView.frame.size.width/@videoPreviewView.frame.size.height
              focusPoint = @captureManager.videoInput.device.focusPointOfInterest
              newCenterY = focusPoint.x * @videoPreviewView.frame.size.width * 1/ratio
              newCenterX = (1.0 - focusPoint.y) * @videoPreviewView.frame.size.height * ratio
            end 
          end
        end

        cameraButtonView = UIView.alloc.initWithFrame([[App.frame.size.width/2 - KCameraButtonWidth/2,App.frame.size.height - KbuttonHeight/2 - KbuttonBackgroundHeight/2 - 44.0],[KCameraButtonWidth,KbuttonHeight]])
        cameraButtonView.backgroundColor = [196,225,208].uicolor
        cameraButtonView.layer.cornerRadius = 10.0
        cameraButtonView.layer.masksToBounds = true

        @cameraButton = camera_button
        @cameraButton.frame = [[0,0],[KCameraButtonWidth,KbuttonHeight]]
        cameraButtonView.addSubview(@cameraButton)

        buttonBackgroundView = UIView.alloc.initWithFrame([[0,App.frame.size.height - KbuttonBackgroundHeight - 44.0],[App.frame.size.width, KbuttonBackgroundHeight]])
        buttonBackgroundView.backgroundColor = :white.uicolor

        
        if @captureManager.backFacingCamera.hasTorch
          # add flash button
          torchModeButton = DDExpandableButton.alloc.initWithPoint(CGPointMake(10.0, 10.0),
                                             leftTitle:'flash.png'.uiimage,
                                             buttons:['Auto', 'On', 'Off'])
          torchModeButton.addTarget(self, action:'toggleFlashlight:', forControlEvents:UIControlEventValueChanged)
          torchModeButton.setVerticalPadding(6)
          torchModeButton.setSelectedItem(2)
          torchModeButton.updateDisplay
        end

        #  add front camera toggle button
        if @captureManager.frontFacingCamera
          cameraModeButtonView = UIView.alloc.initWithFrame([[App.frame.size.width - 87.0 - 10.0,10.0],[87.0, 32.00]])
          cameraModeButtonView.backgroundColor = :white.uicolor
          cameraModeButtonView.alpha = 0.4
          cameraModeButtonView.layer.cornerRadius = 16.0
          cameraModeButtonView.layer.borderColor = :white.uicolor.CGColor
          cameraModeButtonView.layer.borderWidth = 1.0
          cameraButtonImageView = UIImageView.alloc.initWithImage('PLCameraToggleIcon.png'.uiimage)
          cameraButtonImageView.backgroundColor = :clear.uicolor
          cameraButtonImageView.center = cameraModeButtonView.center
          cameraModeButton = UIButton.buttonWithType(UIButtonTypeCustom)
          cameraModeButton.frame = cameraModeButtonView.frame
          cameraModeButton.backgroundColor = :clear.uicolor
          cameraModeButton.layer.cornerRadius = 16.0
          cameraModeButton.layer.borderColor = :black.uicolor.CGColor
          cameraModeButton.layer.borderWidth = 1.0
          cameraModeButton.addTarget(self, action:'toggleCamera:', forControlEvents:UIControlEventTouchUpInside)
          @videoPreviewView.addSubview(cameraModeButtonView)
          @videoPreviewView.addSubview(cameraButtonImageView)
          @videoPreviewView.addSubview(cameraModeButton)
        end

        self.view.addSubview(buttonBackgroundView)
        self.view.addSubview(cameraButtonView)
        self.view.addSubview(@videoPreviewView)
        self.view.addSubview(torchModeButton) if torchModeButton
      end   
    end
  end

  def viewWillAppear(animated)
    super
    @cameraButton.enabled = true
    @captureManager.session.startRunning if @captureManager.session.isInterrupted
  end

  def toggleCamera(sender)
      # Toggle between cameras when there is more than one
      @captureManager.toggleCamera
      
      # Do an initial focus
      @captureManager.continuousFocusAtPoint(CGPointMake(0.5, 0.5))
  end

  def toggleFlashlight(sender)
    if @captureManager.backFacingCamera.hasTorch and @captureManager.backFacingCamera.hasFlash
      @captureManager.backFacingCamera.lockForConfiguration(nil)
      case @captureManager.backFacingCamera.torchMode
        when AVCaptureTorchModeAuto
          @captureManager.backFacingCamera.setTorchMode(AVCaptureTorchModeOn)
          @captureManager.backFacingCamera.setFlashMode(AVCaptureFlashModeOn)
        when AVCaptureTorchModeOn
          @captureManager.backFacingCamera.setTorchMode(AVCaptureTorchModeOff)
          @captureManager.backFacingCamera.setFlashMode(AVCaptureFlashModeOff)
        when AVCaptureTorchModeOff
          @captureManager.backFacingCamera.setTorchMode(AVCaptureTorchModeAuto)
          @captureManager.backFacingCamera.setFlashMode(AVCaptureFlashModeAuto)
      end
      @captureManager.backFacingCamera.unlockForConfiguration
    end   
  end

  def captureStillImage(sender)
    # Capture a still image
    @captureManager.captureStillImage
    
    # Flash the screen white and fade it out to give UI feedback that a still image was taken
    unless @captureManager.backFacingCamera.isFlashActive
      flashView = UIView.alloc.initWithFrame(@videoPreviewView.bounds)
      flashView.backgroundColor = :white.uicolor
      @videoPreviewView.addSubview(flashView)
      
      UIView.animateWithDuration(0.4,
        animations:lambda {
          flashView.alpha = 0
        },
        completion:lambda do |finished|
          flashView.removeFromSuperview
        end
       )
    end
  end

  # Auto focus at a particular point. The focus mode will change to locked once the auto focus happens.
  def tapToAutoFocus(gesture)
    if @captureManager.videoInput.device.isFocusPointOfInterestSupported
      tapPoint = gesture.locationInView(@videoPreviewView)
      convertedFocusPoint = convertToPointOfInterestFromViewCoordinates(tapPoint)
      @captureManager.autoFocusAtPoint(convertedFocusPoint)
    end
  end

  # Change to continuous auto focus. The camera will constantly focus at the point choosen.
  def tapToContinouslyAutoFocus(gesture)
    if @captureManager.videoInput.device.isFocusPointOfInterestSupported
      @captureManager.continuousFocusAtPoint(CGPointMake(0.5,0.5))
    end
  end

  def convertToPointOfInterestFromViewCoordinates(viewCoordinates)
    pointOfInterest = CGPointMake(0.5,0.5)
    frameSize = @videoPreviewView.frame.size
    
    if @captureVideoPreviewLayer.connection.isVideoMirrored
      viewCoordinates.x = frameSize.width - viewCoordinates.x
    end    

    if @captureVideoPreviewLayer.videoGravity == AVLayerVideoGravityResize
      # Scale, switch x and y, and reverse x
      pointOfInterest = CGPointMake(viewCoordinates.y / frameSize.height, 1.0 - (viewCoordinates.x / frameSize.width))
    else
      cleanAperture = nil
      for port in @captureManager.videoInput.ports
        if port.mediaType == AVMediaTypeVideo
          cleanAperture = CMVideoFormatDescriptionGetCleanAperture(port.formatDescription, true)
          apertureSize = cleanAperture.size
          point = viewCoordinates

          apertureRatio = apertureSize.height / apertureSize.width
          viewRatio = frameSize.width / frameSize.height
          xc = 0.5
          yc = 0.5
          
          if @captureVideoPreviewLayer.videoGravity == AVLayerVideoGravityResizeAspect
            if (viewRatio > apertureRatio)
              y2 = frameSize.height
              x2 = frameSize.height * apertureRatio
              x1 = frameSize.width
              blackBar = (x1 - x2) / 2
              # If point is inside letterboxed area, do coordinate conversion otherwise, don't change the default value returned (.5,.5)
              if (point.x >= blackBar and point.x <= blackBar + x2)
              # Scale (accounting for the letterboxing on the left and right of the video preview), switch x and y, and reverse x
                xc = point.y / y2
                yc = 1.0 - ((point.x - blackBar) / x2)
              end
            else
              y2 = frameSize.width / apertureRatio
              y1 = frameSize.height
              x2 = frameSize.width
              blackBar = (y1 - y2) / 2
              # If point is inside letterboxed area, do coordinate conversion. Otherwise, don't change the default value returned (.5,.5)
              if (point.y >= blackBar and point.y <= blackBar + y2)
              # Scale (accounting for the letterboxing on the top and bottom of the video preview), switch x and y, and reverse x
                xc = ((point.y - blackBar) / y2)
                yc = 1.0 - (point.x / x2)
              end
            end
          elsif @captureVideoPreviewLayer.videoGravity == AVLayerVideoGravityResizeAspectFill
            # Scale, switch x and y, and reverse x
            if (viewRatio > apertureRatio)
              y2 = apertureSize.width * (frameSize.width / apertureSize.height)
              xc = (point.y + ((y2 - frameSize.height) / 2.0)) / y2 # Account for cropped height
              yc = (frameSize.width - point.x) / frameSize.width
            else
              x2 = apertureSize.height * (frameSize.height / apertureSize.width)
              yc = 1.0 - ((point.x + ((x2 - frameSize.width) / 2)) / x2) # Account for cropped width
              xc = point.y / frameSize.height
            end
          end
          pointOfInterest = CGPointMake(xc, yc)
          break
        end
      end
    end
    return pointOfInterest
  end

  def stringForFocusMode(focusMode)
    focusString = ''
    case focusMode
      when AVCaptureFocusModeLocked
        focusString = 'locked'
      when AVCaptureFocusModeAutoFocus
        focusString = 'auto'
      when AVCaptureFocusModeContinuousAutoFocus
        focusString = 'continuous'
    end
    return focusString
  end

  def captureManagerStillImageCaptured(image)
    App.alert('Your photo was saved!')
  end

  def dealloc
    Logger.info("CamViewController dealloc")
    self.removeObserver(self, forKeyPath:'captureManager.videoInput.device.focusMode')
    super
  end

end