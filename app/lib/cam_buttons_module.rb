module CamButtons

  def camera_button
    cameraButton = UIButton.buttonWithType(UIButtonTypeRoundedRect)
    cameraButton.titleLabel.font = UIFont.fontWithName('FontAwesome', size:28.0)
    cameraButton.setTitle("\uf030", forState:UIControlStateNormal)
    cameraButton.addTarget(self, action:'captureStillImage:', forControlEvents:UIControlEventTouchUpInside)
    return cameraButton
  end

end