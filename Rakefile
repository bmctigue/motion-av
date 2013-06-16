# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
require 'motion/project/template/ios'
require 'rubygems'
require 'bubble-wrap/core'
require 'bubble-wrap/camera'
require 'bubble-wrap/reactor'
require 'sugarcube'
require 'sugarcube-gestures'
require 'bundler'
require 'motion-cocoapods'
require 'ib'

Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  # app.name = 'motion-av'

  app.name = 'Motion-AV'
  app.identifier = '########'
  app.version = '########'
  app.sdk_version = '6.1'
  app.deployment_target = '6.0'
  app.prerendered_icon = true
  app.interface_orientations = [:portrait]
  app.seed_id = '########'
  app.entitlements['application-identifier'] = app.seed_id + '.' + app.identifier
  app.entitlements['keychain-access-groups'] = [
    app.seed_id + '.*'
  ]
  app.development do
    app.codesign_certificate = '########'
    app.provisioning_profile = '########'
    app.entitlements['aps-environment'] = 'development'
    app.entitlements['get-task-allow']  = true
  end

  app.pods do
    pod 'UI7Kit'
    pod 'DDExpandableButton', '~> 0.0.1'
  end

  app.libs += ['/usr/lib/libz.dylib', '/usr/lib/libsqlite3.dylib']

  app.info_plist['UIAppFonts'] = ['FontAwesome.otf','Handlee-Regular.ttf']

  app.frameworks += [
    'AssetsLibrary',
    'AudioToolbox',
    'AVFoundation',
    'CoreGraphics',
    'CoreImage',
    'CoreMedia',
    'CoreVideo',
    'Foundation',
    'ImageIO',
    'MediaPlayer',
    'MessageUI',
    'MobileCoreServices',
    'OpenGLES',
    'QuartzCore',
    'SystemConfiguration',
    'UIKit'
    ]
end
