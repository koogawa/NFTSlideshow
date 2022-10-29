#import <Foundation/Foundation.h>


@interface ViewUtil : NSObject {

}

+ (UIView *)createTitleViewWithRect:(CGRect)frame title:(NSString *)title;
+ (UIImage*)resizeImage:(UIImage*)image scaledToSize:(CGSize)newSize;

@end
