// Generated by IB v0.2.7 gem. Do not edit it manually
// Run `rake ib:open` to refresh

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

@interface ParserError: StandardError







@end


@interface NSNotificationCenter





-(IBAction) observers;
-(IBAction) unobserve:(id) observer;

@end


@interface NSURLRequest





-(IBAction) to_s;

@end


@interface Camera





-(IBAction) imagePickerControllerDidCancel:(id) picker;
-(IBAction) picker;
-(IBAction) dismiss;
-(IBAction) camera_device;
-(IBAction) media_type_to_symbol:(id) media_type;
-(IBAction) symbol_to_media_type:(id) symbol;
-(IBAction) error:(id) type;

@end


@interface UIView





-(IBAction) handle_gesture:(id) recognizer;

@end


@interface UIAlertView





-(IBAction) style;
-(IBAction) cancel_button_index;

@end


@interface ClickedButton





-(IBAction) willPresentAlertView:(id) alert;
-(IBAction) didPresentAlertView:(id) alert;
-(IBAction) alertViewCancel:(id) alert;
-(IBAction) alertViewShouldEnableFirstOtherButton:(id) alert;
-(IBAction) plain_text_field;
-(IBAction) secure_text_field;
-(IBAction) login_text_field;
-(IBAction) password_text_field;

@end


@interface UIViewController





-(IBAction) content_frame;

@end


@interface PeriodicTimer





-(IBAction) cancel;

@end


@interface Queue





-(IBAction) initialize;
-(IBAction) size;

@end


@interface Timer





-(IBAction) cancel;

@end


@interface UIView





-(IBAction) sugarcube_handle_gesture:(id) recognizer;

@end


@interface CameraViewController: UIViewController





-(IBAction) viewDidLoad;

@end


@interface WelcomeViewController: UIViewController

@property IBOutlet UIButton * openCameraButton;



-(IBAction) viewDidLoad;
-(IBAction) openCamera;

@end



