//
//  ViewController.m
//  Renstagram
//
//  Created by Ivan Ruiz Monjo on 18/08/14.
//  Copyright (c) 2014 Rens Gang. All rights reserved.
//

#import "MyProfileViewController.h"
#import "PhotoDetailViewController.h"
#import "LogInViewController.h"
#import "SignUpViewController.h"
#import "CustomCollectionViewCell.h"
#import "Helper.h"

@interface MyProfileViewController () <PFSignUpViewControllerDelegate, PFLogInViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property NSArray *photosArray; //Of PFObject

@end

@implementation MyProfileViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]];
    if ([PFUser currentUser]) {
        [self displayUserPhotos];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (![PFUser currentUser]) { // No user logged in
        [self showLoginView];
    } else {
        self.title = [NSString stringWithFormat:@"My Profile (%@)", [PFUser currentUser].username];
    }

}

- (void)displayUserPhotos
{
    PFQuery *query = [PFQuery queryWithClassName:@"Photo"];
    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    [query orderByDescending:@"createdAt"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.photosArray = objects;
        [self.collectionView reloadData];
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"detail"]) {
        PhotoDetailViewController *pdvc = segue.destinationViewController;
        NSIndexPath *indexPath = [self.collectionView indexPathsForSelectedItems].firstObject;
        pdvc.photo = [self.photosArray objectAtIndex:indexPath.row];
    }
}

#pragma mark - Loggin in and out

-(void)showLoginView
{
    //custom login view controller
    LogInViewController *logInViewController = [[LogInViewController alloc] init];
    logInViewController.fields = PFLogInFieldsUsernameAndPassword | PFLogInFieldsLogInButton | PFLogInFieldsFacebook | PFLogInFieldsTwitter | PFLogInFieldsSignUpButton |PFLogInFieldsPasswordForgotten;
    logInViewController.delegate = self;

    SignUpViewController *signUpViewController = [[SignUpViewController alloc] init];
    signUpViewController.fields = PFSignUpFieldsUsernameAndPassword | PFSignUpFieldsEmail | PFSignUpFieldsSignUpButton | PFSignUpFieldsDismissButton | PFSignUpFieldsAdditional | PFSignUpFieldsDefault;
    [signUpViewController setDelegate:self];

    [logInViewController setSignUpController:signUpViewController];

    [self presentViewController:logInViewController animated:YES completion:NULL];
}

- (IBAction)logoutButtonPressed:(id)sender
{
    [PFUser logOut];
    [self showLoginView];
}

#pragma mark - Parse delegate
- (void)signUpViewController:(PFSignUpViewController *)signUpController didSignUpUser:(PFUser *)user
{
    [signUpController dismissViewControllerAnimated:YES completion:nil];
}

- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self displayUserPhotos];
}

#pragma mark - Collection View delegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.photosArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CustomCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    PFObject *photo = [self.photosArray objectAtIndex:indexPath.row];
    PFFile *file = [photo objectForKey:@"photo"];
    [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (!error) {
            //[cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            UIImage *image = [UIImage imageWithData:data];

            cell.imageView.image = [Helper roundedRectImageFromImage:image withRadious:9];
            cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
            cell.descriptionLabel.text = [photo objectForKey:@"description"];

            NSDate *photoDate = [photo createdAt];
            NSDateFormatter *dateFormat = [NSDateFormatter new];
            dateFormat.timeStyle = NSDateFormatterShortStyle;
            dateFormat.dateStyle = NSDateFormatterShortStyle;
            cell.infoLabel.text = [NSString stringWithFormat:@"on %@", [dateFormat stringFromDate:photoDate]];

            PFQuery *query = [PFQuery queryWithClassName:@"Comment"];
            [query whereKey:@"photo" equalTo:photo];
            [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
                cell.commentsLabel.text = [NSString stringWithFormat:@"%d comments", number];
            }];
            
        }
    }];
    return cell;
}


@end