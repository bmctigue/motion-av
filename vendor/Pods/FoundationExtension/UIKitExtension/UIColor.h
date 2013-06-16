//
//  UIColor.h
//  FoundationExtension
//
//  Created by Jeong YunWon on 10. 10. 5..
//  Copyright 2010 youknowone.org All rights reserved.
//

@class UIAColorComponents;

/*!
 *  @file
 *  @brief [UIColor][0] shortcut method category extensions.
 *      [0]: http://developer.apple.com/library/ios/#documentation/UIKit/Reference/UIColor_Class/Reference/Reference.html
 */

/*!
 *  @brief UIColor shortcuts
 */
@interface UIColor (Shortcuts)

//! @brief Color component property. nil if unavailable.
@property(nonatomic, readonly) UIAColorComponents *components;

@end

/*!
 *  @brief UIColor creation shortcuts
 */
@interface UIColor (Creations)

/*!
 *  @brief Initialize color from 32bit color component
 *  @param red
 *      Value from 0 to 255
 *  @param green
 *      Value from 0 to 255
 *  @param blue
 *      Value from 0 to 255
 *  @param alpha
 *      Value from 0 to 255
 */
- (id)initWith8bitRed:(UInt8)red green:(UInt8)green blue:(UInt8)blue alpha:(UInt8)alpha;
/*!
 *  @brief Creates and returns color from 32bit color component
 *  @see initWith8bitRed:green:blue:alpha:
 */
+ (id)colorWith8bitRed:(UInt8)red green:(UInt8)green blue:(UInt8)blue alpha:(UInt8)alpha;

/*!
 *  @brief Initialize color from 8bit white component
 *  @param white
 *      Value from 0 to 255
 *  @param alpha
 *      Value from 0 to 255
 */
- (id)initWith8bitWhite:(UInt8)red alpha:(UInt8)alpha;

/*!
 *  @brief Creates and returns color from 8bit white component
 *  @see initWith8bitWhite:alpha:
 */
+ (UIColor *)colorWith8BitWhite:(UInt8)white alpha:(UInt8)alpha;

/*!
 *  @brief Initialize color from 32bit color packed value
 *  @param value
 *      Packed 32bit color value.
 */
- (id)initWith32bitColor:(UInt32)value;
/*!
 *  @brief Creates and returns color from 32bit color packed value
 *  @see initWith32bitColor:
 */
+ (id)colorWith32bitColor:(UInt32)value;

@end

/*!
 *  @brief UIColor HTML color creations
 */
@interface UIColor (HTMLColor)

/*!
 *  @brief Initialize with html color code
 *  @details This accept formats as like "#fff" or "#0f0f0f" for formal colors. "#dddf" or "#fdfdfdff" for alpha value. If "#" prefix doesn't exist, select constant from HTML color name table. "orange" for css and "transperent" for clear color.
 */
- (UIColor *)initWithHTMLExpression:(NSString *)code;

/*!
 *  @brief Creates and returns color object with html color code
 *  @details This accept formats as like "#fff" or "#0f0f0f" for formal colors. "#dddf" or "#fdfdfdff" for alpha value. If "#" prefix doesn't exist, select constant from HTML color name table. "orange" for css and "transperent" for clear color.
 */
+ (UIColor *)colorWithHTMLExpression:(NSString *)code;

@end


/*!
 *  @brief UIColor component interface
 */
@interface UIAColorComponents: NSObject {
    CGFloat _components[4];
}

//! @brief Red component
@property(nonatomic, readonly) CGFloat red;
//! @brief Green component
@property(nonatomic, readonly) CGFloat green;
//! @brief Blue component
@property(nonatomic, readonly) CGFloat blue;
//! @brief Alpha component
@property(nonatomic, readonly) CGFloat alpha;

/*!
 *  @brief Initialize color components from color
 *  @param color
 *      An UIColor
 */
- (id)initWithColor:(UIColor *)color;
/*!
 *  @brief Creates and returns color components from color
 *  @see initWithColor:
 */
+ (id)componentsWithColor:(UIColor *)color;

@end
