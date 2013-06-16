class WelcomeViewController < UIViewController

  extend IB

  outlet :openCameraButton, UIButton
  
  def viewDidLoad
    super
    self.navigationItem.title = 'Motion-AV'
  end

  def openCamera
    if Device.rear_camera?
      self.navigationController.pushViewController(CamViewController.sharedInstance, animated:true)
    else
      App.alert("Sorry, you need a camera!")
    end
  end

end
