class CamRecorder

  attr_accessor :session, :movieFileOutput, :outputFileURL, :delegate


  def initWithSession(aSession, outputFileURL:anOutputFileURL)
    @movieFileOutput = AVCaptureMovieFileOutput.new
    aSession.addOutput(@movieFileOutput) if aSession.canAddOutput(@movieFileOutput)
    @session = aSession
    @outputFileURL = anOutputFileURL
    return self
  end

  def recordsVideo
    videoConnection = CamUtilities.connectionWithMediaType(AVMediaTypeVideo, fromConnections:@movieFileOutput.connections)
    return videoConnection.isActive
  end

  def recordsAudio
    audioConnection = CamUtilities.connectionWithMediaType(AVMediaTypeAudio, fromConnections:@movieFileOutput.connections)
    return audioConnection.isActive
  end

  def isRecording
    return @movieFileOutput.isRecording
  end

  def startRecordingWithOrientation(videoOrientation)
    videoConnection = CamUtilities.connectionWithMediaType(AVMediaTypeVideo, fromConnections:@movieFileOutput.connections)
    videoConnection.setVideoOrientation(videoOrientation) if videoConnection.isVideoOrientationSupported
    @movieFileOutput.startRecordingToOutputFileURL(@outputFileURL, recordingDelegate:self)
  end

  def stopRecording
    @movieFileOutput.stopRecording
  end

  # delegate methods

  def captureOutput(captureOutput, didStartRecordingToOutputFileAtURL:fileURL, fromConnections:connections) 
    if @delegate.respondsToSelector('recorderRecordingDidBegin:')
      @delegate.recorderRecordingDidBegin(self)
    end
  end

  def captureOutput(captureOutput, didFinishRecordingToOutputFileAtURL:anOutputFileURL, fromConnections:connections, error:error)
    if @delegate.respondsToSelector('recorder:recordingDidFinishToOutputFileURL:error:')
      @delegate.recorder(self, recordingDidFinishToOutputFileURL:anOutputFileURL, error:error)
    end
  end
  
  def dealloc
    @session.removeOutput(@movieFileOutput)
    super
  end

end