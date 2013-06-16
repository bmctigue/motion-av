class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    UI7KitPatchAll(false)

    welcomeViewController = WelcomeViewController.alloc.initWithNibName('WelcomeViewController', bundle:nil)
    navController = UINavigationController.alloc.initWithRootViewController(welcomeViewController)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @window.rootViewController = navController
    @window.makeKeyAndVisible

    true
  end
end
