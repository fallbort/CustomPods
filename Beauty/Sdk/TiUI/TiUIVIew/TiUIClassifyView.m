//
//  TiUIClassifyView.m
//  TiFancy
//
//  Created by iMacA1002 on 2020/4/26.
//  Copyright © 2020 Tillusory Tech. All rights reserved.
//

#import "TiUIClassifyView.h"
#import "TiConfig.h"
#import "TiButton.h"
@import MeMeKit;

#define MINIMUMLINESPACING  (SCREEN_WIDTH - 4*TiUISubMenuOneViewTiButtonWidth)/5

@interface TiUIClassifyView ()<UICollectionViewDelegate,UICollectionViewDataSource>

@property (strong, nonatomic) UIPageControl *pageControl;

@end

@implementation TiUIClassifyView

static NSString *const TiUIClassifyViewCellId = @"TiUIClassifyViewCellId";

- (NSArray *)modArr{
    if (!_modArr) {
        _modArr= @[
            @{
                @"name":@"美颜",
                @"icon":@"icon_gongneng_meiyan.png",
                @"TIMenuClassify":@[@(10),@(4),@(0),@(1),@(13),@(6)]
            },
            @{
                @"name":@"滤镜",
                @"icon":@"icon_gongneng_lvjing.png",
                @"TIMenuClassify":@[@(5)]
            },
            @{
                @"name":@"萌颜",
                @"icon":@"icon_gongneng_mengyan.png",
                @"TIMenuClassify":@[@(2),@(11),@(8),@(3),@(7),@(9),@(14),@(16),@(17)]
            },
            @{
                @"name":@"美妆",
                @"icon":@"icon_gongneng_meizhuang.png",
                @"TIMenuClassify":@[@(12),@(15)]
            },
            
        ];
    }
    return _modArr;
}

- (void)setModType{
    
    if (!_iconArr) {
        _iconArr = [[NSMutableArray alloc] init];
    }
    if (_iconArr.count>0) {
        [_iconArr removeAllObjects];
    }
    [_iconArr addObject:@"icon_gongneng_meiyan"];
    [_iconArr addObject:@"icon_gongneng_lvjing"];
    [_iconArr addObject:@"icon_gongneng_mengyan"];
    [_iconArr addObject:@"icon_gongneng_meizhuang"];
    _titleColor = TI_RGB_Alpha(255.0, 255.0, 255.0, 1.0);
    
    [_classifyMenuView reloadData];
    
}

- (UICollectionView *)classifyMenuView{
     if (!_classifyMenuView) {
         UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
         layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
         layout.itemSize = CGSizeMake(TiUISubMenuOneViewTiButtonWidth, TiUISubMenuOneViewTiButtonHeight);

         _classifyMenuView =[[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
         _classifyMenuView.showsHorizontalScrollIndicator = NO;
         _classifyMenuView.backgroundColor=[UIColor clearColor];
         _classifyMenuView.pagingEnabled = YES;
         _classifyMenuView.dataSource= self;
         _classifyMenuView.delegate = self;
         [_classifyMenuView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:TiUIClassifyViewCellId];
         
     }
     return _classifyMenuView;
 }

- (UIPageControl *)pageControl{
    if (!_pageControl) {
        _pageControl = [[UIPageControl alloc]init];
        // 设置页码
        _pageControl.numberOfPages = 2;
        _pageControl.currentPage = 0;
        _pageControl.currentPageIndicatorTintColor = TI_RGB_Alpha(88.0, 221.0, 221.0, 1.0);
        _pageControl.pageIndicatorTintColor = TI_RGB_Alpha(189.0, 189.0, 189.0, 1.0);
        [_pageControl setHidden:YES];
    }
    return _pageControl;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setBackgroundColor:TI_RGB_Alpha(45.0, 45.0, 45.0, 0.6)];
        [self setModType];
        
        [self addSubview:self.classifyMenuView];
        [self.classifyMenuView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self);
            make.left.right.equalTo(self);
            make.height.mas_equalTo(75);
        }];
        
        [self addSubview:self.pageControl];
        [self.pageControl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self);
            make.top.equalTo(self.classifyMenuView.mas_bottom).with.offset(30);
            make.width.mas_equalTo(80);
            make.height.mas_equalTo(20);
        }];
        
    }
    return self;
}

#pragma mark - <UIScrollViewDelegate>
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat pageWidth = self.classifyMenuView.frame.size.width;
    int page = floor((self.classifyMenuView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    self.pageControl.currentPage = page;
}

#pragma mark ---UICollectionViewDataSource---
//设置每个section包含的item数目
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.modArr.count;
}
   
 //返回对应indexPath的cell
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:TiUIClassifyViewCellId forIndexPath:indexPath];
    //移除重新添加
    [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSDictionary *dic = self.modArr[indexPath.row];
    
    TiButton *cellBtn = [[TiButton alloc]initWithScaling:0.9];
    cellBtn.userInteractionEnabled = NO;
    
    NSString *name = [dic valueForKey:@"name"];
    if ([name isEqualToString:@""]) {
          [cellBtn setTitle:[dic valueForKey:@"name"] withImage:nil withTextColor:TI_Color_Default_Text_Black forState:UIControlStateNormal];
    }else{
        [cellBtn setTitle:[dic valueForKey:@"name"] withImage:[UIImage imageNamed:_iconArr[indexPath.row] inBundle:[NSBundle bundleWithPathBundle:@"TiUIData"] withConfiguration:nil] withTextColor:_titleColor forState:UIControlStateNormal];
    }
  
    [cell.contentView addSubview:cellBtn];
    [cellBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.equalTo(cell.contentView);
        make.left.equalTo(cell.contentView.mas_left).offset(6);
        make.right.equalTo(cell.contentView.mas_right).offset(-6);
    }];
    return cell;
  
}

// 定义每个Section的四边间距
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, MINIMUMLINESPACING, 0, MINIMUMLINESPACING);
}
 
// 两行cell之间的间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return MINIMUMLINESPACING;
}
  

#pragma mark ---UICollectionViewDelegate---
//选择了某个cell
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    NSString *name = [self.modArr[indexPath.row] objectForKey:@"name"];
    
//    [self Judge_First:name];    //已弃用
    
    if (![name isEqualToString:@""] && ![self updateMV:name]) {
        [TiUIManager shareManager].tiUIViewBoxView.menuView.hidden = NO;
        [TiUIManager shareManager].tiUIViewBoxView.subMenuView.hidden = NO;
        NSArray *arr = [self.modArr[indexPath.row] objectForKey:@"TIMenuClassify"];
         if (self.clickOnTheClassificationBlock) {
             self.clickOnTheClassificationBlock(arr);
         }
         [self hiddenView];
    }
}

//已弃用
- (void)Judge_First:(NSString *)key{}

- (BOOL)updateMV:(NSString *)key{
    if ([key isEqual:@"美颜"]) {
        //设置重置对象
        resetObject = @"美颜";
        //判断重置按钮状态
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *beautystate = [defaults objectForKey:@"beautystate"];
        if ([beautystate  isEqual: @"optional"]) {
            [[TiUIManager shareManager].tiUIViewBoxView.resetBtn setEnabled:true];
        }else{
            //默认不可点击
            [[TiUIManager shareManager].tiUIViewBoxView.resetBtn setEnabled:false];
        }
        //显示重置按钮
        [TiUIManager shareManager].tiUIViewBoxView.resetBtn.hidden = NO;
    }else if ([key isEqual:@"美妆"]){
        //设置重置对象
        resetObject = @"美妆";
        //判断重置按钮状态
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *makeupstate = [defaults objectForKey:@"makeupstate"];
        if ([makeupstate  isEqual: @"optional"]) {
            [[TiUIManager shareManager].tiUIViewBoxView.resetBtn setEnabled:true];
        }else{
            //默认不可点击
            [[TiUIManager shareManager].tiUIViewBoxView.resetBtn setEnabled:false];
        }
        //显示重置按钮
        [TiUIManager shareManager].tiUIViewBoxView.resetBtn.hidden = NO;
    }else{
        //隐藏重置按钮
        [TiUIManager shareManager].tiUIViewBoxView.resetBtn.hidden = YES;
    }
    if ([key  isEqual: @"萌颜"]) {
        if (self.CutefaceBlock) {
            self.CutefaceBlock(@"萌颜");
        }
    }else{
        if (self.CutefaceBlock) {
            self.CutefaceBlock(@"其他");
        }
    }
    
    return false;
}

- (void)showView{
    
    [UIView animateWithDuration:0.3 animations:^{
        CGRect rect = self.frame;
        rect.origin.y = 0;
        [self setFrame:rect];
       self.alpha = 1;
    }];
    
    if (self.executeShowOrHiddenBlock) {
        self.executeShowOrHiddenBlock(YES);
    }

}

- (void)hiddenView{
    CGRect rect = self.frame;
    rect.origin.y = TiUIViewBoxTotalHeight;
    [self setFrame:rect];
    self.alpha = 0;
    if (self.executeShowOrHiddenBlock) {
        self.executeShowOrHiddenBlock(NO);
    }
}

@end
