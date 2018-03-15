#import "RNGooglePlacesViewController.h"
#import "NSMutableDictionary+GMSPlace.h"

#import <GooglePlaces/GooglePlaces.h>
#import <GooglePlacePicker/GooglePlacePicker.h>
#import <React/RCTUtils.h>
#import <React/RCTLog.h>

@interface RNGooglePlacesViewController ()<GMSAutocompleteViewControllerDelegate, GMSPlacePickerViewControllerDelegate>
@end

@implementation RNGooglePlacesViewController
{
	RNGooglePlacesViewController *_instance;

	RCTPromiseResolveBlock _resolve;
	RCTPromiseRejectBlock _reject;
    GMSPlacePickerViewController *_placePicker;
}

- (instancetype)init 
{
	self = [super init];
	_instance = self;

	return self;
}

- (void)openAutocompleteModal: (GMSAutocompleteFilter *)autocompleteFilter
                       bounds: (GMSCoordinateBounds *)bounds
                     resolver: (RCTPromiseResolveBlock)resolve
                     rejecter: (RCTPromiseRejectBlock)reject;
{
    _resolve = resolve;
    _reject = reject;
    
    GMSAutocompleteViewController *viewController = [[GMSAutocompleteViewController alloc] init];
    viewController.autocompleteFilter = autocompleteFilter;
    viewController.autocompleteBounds = bounds;
	viewController.delegate = self;
    UIViewController *topController = [self getTopController];
	[topController presentViewController:viewController animated:YES completion:nil];
}

- (void)openPlacePickerModal: (GMSCoordinateBounds *)bounds
                    resolver: (RCTPromiseResolveBlock)resolve
					rejecter: (RCTPromiseRejectBlock)reject;
{
	_resolve = resolve;
	_reject = reject;

	GMSPlacePickerConfig *config = [[GMSPlacePickerConfig alloc] initWithViewport:bounds];
    _placePicker = [[GMSPlacePickerViewController alloc] initWithConfig:config];
    [_placePicker setDelegate:self];
}


// Handle the user's selection.
- (void)viewController:(GMSAutocompleteViewController *)viewController
	didAutocompleteWithPlace:(GMSPlace *)place 
{
    UIViewController *topController = [self getTopController];
    [topController dismissViewControllerAnimated:YES completion:nil];
	
	if (_resolve) {
        _resolve([NSMutableDictionary dictionaryWithGMSPlace:place]);
    }
}

- (void)viewController:(GMSAutocompleteViewController *)viewController
	didFailAutocompleteWithError:(NSError *)error 
{
    UIViewController *topController = [self getTopController];
    [topController dismissViewControllerAnimated:YES completion:nil];

	// TODO: handle the error.
	NSLog(@"Error: %@", [error description]);

	_reject(@"E_AUTOCOMPLETE_ERROR", [error description], nil);
}

// User canceled the operation.
- (void)wasCancelled:(GMSAutocompleteViewController *)viewController 
{
    UIViewController *topController = [self getTopController];
    [topController dismissViewControllerAnimated:YES completion:nil];

	_reject(@"E_USER_CANCELED", @"Search cancelled", nil);
}

// Turn the network activity indicator on and off again.
- (void)didRequestAutocompletePredictions:(GMSAutocompleteViewController *)viewController 
{
  	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)didUpdateAutocompletePredictions:(GMSAutocompleteViewController *)viewController 
{
  	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

// User canceled the operation.
- (UIViewController *)getTopController
{
    UIViewController *topController = [UIApplication sharedApplication].delegate.window.rootViewController;
    while (topController.presentedViewController) { topController = topController.presentedViewController; }
    return topController;
}

- (void)placePicker:(nonnull GMSPlacePickerViewController *)viewController didPickPlace:(nonnull GMSPlace *)place {
    if (place) {
        if (_resolve) {
            _resolve([NSMutableDictionary dictionaryWithGMSPlace:place]);
        }
    }
}

- (void)placePicker:(GMSPlacePickerViewController *)viewController didFailWithError:(NSError *)error {
    _reject(@"E_PLACE_PICKER_ERROR", [error localizedDescription], nil);
}

- (void)placePickerDidCancel:(GMSPlacePickerViewController *)viewController {
    _reject(@"E_USER_CANCELED", @"Search cancelled", nil);
}

@end
