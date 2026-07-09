#import "ACTouchForwardingView.h"
#import "PrivateHeaders.h"
#import <IOKit/hid/IOHIDEvent.h>
#import <mach/mach_time.h>

// ---------------------------------------------------------------------------
//  Touch forwarding is the fiddliest part of the whole tweak and the most
//  version-sensitive. The hosted (remote) layer only shows pixels; it does NOT
//  receive touches. We capture UITouches here, convert them to the app scene's
//  coordinate space, and synthesize a digitizer HID event routed to that scene.
//
//  Two viable backends (pick per OS):
//    A) BackBoardServices:  BKSHIDEventSetDigitizerInfo + BKSHIDEventRegisterEvent
//       and route with -[FBScene ...] / BKSHIDEventDeferringToken.
//    B) IOHIDEvent + IOHIDEventSystemClient, tagged with the scene's contextId.
//
//  Below is backend A in pseudo-form. The exact selectors that route an event
//  to a specific scene changed on iOS 17/18; verify on-device.
// ---------------------------------------------------------------------------

@implementation ACTouchForwardingView

- (void)sendTouchAt:(CGPoint)p phase:(UITouchPhase)phase {
    // Normalize to 0..1 in the car display space, then map into the app scene.
    CGSize size = self.bounds.size;
    if (size.width <= 0 || size.height <= 0) return;
    IOHIDFloat nx = p.x / size.width;
    IOHIDFloat ny = p.y / size.height;

    Boolean touching = (phase != UITouchPhaseEnded && phase != UITouchPhaseCancelled);

    uint64_t ts = mach_absolute_time();
    AbsoluteTime timeStamp;
    timeStamp.lo = (uint32_t)(ts & 0xFFFFFFFF);
    timeStamp.hi = (uint32_t)(ts >> 32);

    IOHIDEventRef parent = IOHIDEventCreateDigitizerEvent(
        kCFAllocatorDefault, timeStamp, /*kIOHIDDigitizerTransducerTypeHand*/ 2,
        0, 0, /*eventMask*/ (touching ? 0x1 : 0), 0,
        nx, ny, 0, 0, 0, false, touching, 0);
    if (!parent) return;

    IOHIDEventRef finger = IOHIDEventCreateDigitizerFingerEvent(
        kCFAllocatorDefault, timeStamp, 1, 2,
        /*eventMask*/ (touching ? 0x1 : 0),
        nx, ny, 0, 0, 0, touching, touching, 0);
    if (finger) {
        IOHIDEventAppendEvent(parent, finger);
        CFRelease(finger);
    }

    // TODO(device): route `parent` to self.scene rather than the main display.
    // On iOS 14-16:  BKSHIDEventRouter / -[FBScene deliverHIDEvent:] style APIs.
    // On iOS 17-18:  the scene now takes a deferring/eligibility token first.
    // Without scene-targeted routing the event lands on the MAIN screen's app.
    //
    // Placeholder call site kept explicit so it is obvious what must be wired:
    //   [self routeHIDEvent:parent toScene:self.scene];

    CFRelease(parent);
}

- (void)routeHIDEvent:(IOHIDEventRef)event toScene:(FBScene *)scene {
    // TODO(device): implement per-OS. Left unimplemented on purpose — this is
    // the one spot that genuinely needs testing against your target firmware.
}

#pragma mark - UIKit touch capture

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *t = touches.anyObject;
    [self sendTouchAt:[t locationInView:self] phase:UITouchPhaseBegan];
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *t = touches.anyObject;
    [self sendTouchAt:[t locationInView:self] phase:UITouchPhaseMoved];
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *t = touches.anyObject;
    [self sendTouchAt:[t locationInView:self] phase:UITouchPhaseEnded];
}
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *t = touches.anyObject;
    [self sendTouchAt:[t locationInView:self] phase:UITouchPhaseCancelled];
}

@end
