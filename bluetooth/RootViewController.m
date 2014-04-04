//
//  RootViewController.m
//  bluetooth
//
//  Created by jason on 4/4/14.
//  Copyright (c) 2014 jason. All rights reserved.
//

#import "RootViewController.h"
#import "ScanViewController.h"

@interface RootViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>
@property (nonatomic, strong) UIPageViewController *pageVC;
@property (nonatomic, strong) NSMutableArray *viewControllers;
@end

@implementation RootViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma memeory management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma view lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // -------------------- page view controller --------------------
    
    self.pageVC = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    
    self.pageVC.dataSource = self;
    self.pageVC.delegate = self;
    
    self.pageVC.view.frame = self.view.bounds;
    self.pageVC.view.backgroundColor = [UIColor blackColor];
    
    [self addChildViewController:self.pageVC];
    [self.view addSubview:self.pageVC.view];
    [self.pageVC didMoveToParentViewController:self];
    
    // get the first page
    [self.pageVC setViewControllers:@[[self getPageViewController:0]]
                          direction:UIPageViewControllerNavigationDirectionForward
                           animated:NO
                         completion:nil];
}

#pragma mark - UIPageViewControllerDataSource

// create a view controller to show an img
- (UIViewController *)getPageViewController:(int)index
{
    UIViewController *vc = self.viewControllers[index];
    
    return vc;
}

// handles showing next img (if exists)
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    int nextIndex = [self.viewControllers indexOfObject:viewController] + 1;
    
    if(nextIndex >= self.viewControllers.count)
        return nil;
    else
        return [self getPageViewController:nextIndex];
}

// handles showing previous img (if exists)
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    int prevIndex = [self.viewControllers indexOfObject:viewController] - 1;
    
    if(prevIndex < 0)
        return nil;
    else
        return [self getPageViewController:prevIndex];
}

#pragma mark - UIPageViewControllerDelegate

- (void)pageViewController:(UIPageViewController *)pageViewController
        didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray *)previousViewControllers
       transitionCompleted:(BOOL)completed
{
    if(completed)
    {
        
    }
}




@end
