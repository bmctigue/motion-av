# Motion-AV

a port of the vital parts of the Apple AVCam application for use in RubyMotion projects

## Installation

This is a standalone application that will run on Apple devices with a camera. You can download the application, update the rake file with your developer account information, then run the application on your device.

The lib directory has the essential files to support AVFoundation, cam_recorder.rb, cam_utilities.rb, and capture_manager.rb. The lib directory also contains a module with buttons for the sample view controller. 

The controllers directory contains a sample view controller that uses AVFoundation to present a camera that allows you to take photos and save them to the camera roll. It also has sample code to presenting buttons for the torch and rear/front facing cameras.

# Running the app

1. clone it 
2. run `bundle`
3. run `rake` to run app in simulator

**Note** : this app is build for iOS 6.0

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request