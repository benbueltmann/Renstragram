//
//  PictureViewController.m
//  Renstagram
//
//  Created by Ivan Ruiz Monjo on 18/08/14.
//  Copyright (c) 2014 Rens Gang. All rights reserved.
//

#import "AddPictureViewController.h"
#import "TagViewController.h"
#import "Helper.h"

@interface AddPictureViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *descriptionTextField;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property UIImage *image;
@property NSMutableArray *taggedArray;

@end

@implementation AddPictureViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.taggedArray = [NSMutableArray new];
    self.title = @"Add a photo";
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]];
    [self showPicker];
}
- (IBAction)imagePick:(UITapGestureRecognizer *)sender {
    [self showPicker];
}

-(void)showPicker
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.allowsEditing = YES;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

}
- (IBAction)tapOnView:(id)sender {
    [self.view endEditing:YES];
}

-(IBAction)unwind:(UIStoryboardSegue *)sender
{
    // get PFUser from tag view and addObject to mutable array
    TagViewController *tvc = sender.sourceViewController;
    //get PFUser from follow
    PFObject *follower = tvc.selectedObject;
    PFUser *user = [follower objectForKey:@"to"];
    [user fetchIfNeeded];
    [self.taggedArray addObject:user];
    //now we have array of PFUsers
    NSLog(@"%@",self.taggedArray);
}

- (IBAction)addPictureButtonPressed:(id)sender
{
    if (self.imageView.image) {  //Prevent saving blank images.
        PFFile *file = [PFFile fileWithData:UIImagePNGRepresentation(self.imageView.image)];
        PFObject *photo = [PFObject objectWithClassName:@"Photo"];
        [photo setObject:file forKey:@"photo"];
        [photo setObject:self.descriptionTextField.text forKey:@"description"];
        [photo setObject:[PFUser currentUser] forKey:@"user"];
        [photo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            NSLog(@"picture saved!");
            // add tag to associate with photo for PFObject class name "Tag"
            // for everyone in tag array
            for (PFUser *user in self.taggedArray ) {
                PFObject *tag = [PFObject objectWithClassName:@"Tag"];
                [tag setObject:user forKey:@"userGotTag"];
                [tag setObject:photo forKey:@"photoContainTag"];
                [tag saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    NSLog(@"tag saved");
                }];
            }
        }];
        self.descriptionTextField.text = @"";
    }
    [self.descriptionTextField resignFirstResponder];

}


- (IBAction)choseFilterSegmentedControl:(UISegmentedControl *)sender
{
    CIFilter *filter;
    CIImage *beginImage = [CIImage imageWithData:UIImagePNGRepresentation(self.image)];

    switch (sender.selectedSegmentIndex) {
        case 0:
            NSLog(@"no filter!");
            self.imageView.image  = [Helper roundedRectImageFromImage:self.image withRadious:8];
            break;
        case 1:
        {

            filter = [CIFilter filterWithName:@"CISepiaTone"
                                          keysAndValues: kCIInputImageKey, beginImage,
                                @"inputIntensity", @0.8, nil];
            break;
        }
            case 2:
        {
            filter = [CIFilter filterWithName:@"CIPhotoEffectInstant"
                                keysAndValues: kCIInputImageKey, beginImage,
                       nil];
        }
            break;

        default:
            break;
    }
    if (sender.selectedSegmentIndex) {
        CIImage *outputImage = [filter outputImage];
        UIImage *newImage = [UIImage imageWithCIImage:outputImage];
        self.imageView.image = [Helper roundedRectImageFromImage:newImage withRadious:8];
    }

}


#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:@"UIImagePickerControllerEditedImage"];
    self.imageView.image = [Helper roundedRectImageFromImage:image withRadious:8];
    self.image = image;
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
