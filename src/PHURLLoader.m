//
//  PHURLLoader.m
//  playhaven-sdk-ios
//
//  Created by Jesus Fernandez on 2/9/11.
//  Copyright 2011 Playhaven. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "PHURLLoader.h"
#import "PHConstants.h"

#define MAXIMUM_REDIRECTS 10

@interface PHURLLoader(Private)
+(NSMutableSet *)allLoaders;
-(void)finish;
-(void)fail;
-(void)_launchURL:(NSURL *)targetURL;
@end

@implementation PHURLLoader

@synthesize delegate = _delegate;
@synthesize targetURL = _targetURL;
@synthesize opensFinalURLOnDevice = _opensFinalURLOnDevice;
@synthesize context = _context;

#pragma mark -
#pragma mark Static

+(PHURLLoader *) openDeviceURL:(NSString *)url{
    PHURLLoader *result = [[[PHURLLoader alloc] init] autorelease];
    result.targetURL = [NSURL URLWithString:url];
    [result open];
    
    return result;
}

+(NSMutableSet *)allLoaders{
    static NSMutableSet *allLoaders = nil;
    
    if (allLoaders == nil) {
        allLoaders = [[NSMutableSet alloc] init];
    }
    
    return allLoaders;
}

+(void)invalidateAllLoadersWithDelegate:(id<PHURLLoaderDelegate>)delegate{
    NSEnumerator *allLoaders = [[PHURLLoader allLoaders] objectEnumerator];
    PHURLLoader *loader = nil;
    
    NSMutableSet *invalidatedLoaders = [NSMutableSet set];
    
    while (loader = [allLoaders nextObject]){
        if ([[loader delegate] isEqual:delegate]) {
            [invalidatedLoaders addObject:loader];
        }
    }
    
    [invalidatedLoaders makeObjectsPerformSelector:@selector(invalidate)];
}


#pragma mark -
#pragma mark Instance
-(id)init{
    if ((self = [super init])) {
        _opensFinalURLOnDevice = YES;
    }
    
    return self;
}

-(void) dealloc{
    [_targetURL release], _targetURL = nil;
    [_connection release], _connection = nil;
    [_context release], _context = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark PHURLLoader
-(void) open{
    if (!!self.targetURL) {
        PH_LOG(@"opening url %@", self.targetURL);
        _totalRedirects = 0;
        NSURLRequest *request = [NSURLRequest requestWithURL:self.targetURL];
        
        @synchronized(self){
            [_connection cancel];
            [_connection release], _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
            
            
            //PHURLLOADER_RETAIN see PHURLLOADER_RELEASE
            [[PHURLLoader allLoaders] addObject:self];
        }
    }
}

-(void) invalidate{
    self.delegate = nil;
    
    //PHURLLOADER_RELEASE see PHURLLOADER_RETAIN
    @synchronized(self){
        [_connection cancel];
        [[PHURLLoader allLoaders] removeObject:self];
    }
}

-(void)finish{
    if ([[UIApplication sharedApplication] canOpenURL:self.targetURL]) {
        if ([self.delegate respondsToSelector:@selector(loaderFinished:)]) {
            [self.delegate loaderFinished:self];
        }
        
        [self invalidate];
        
        if (self.opensFinalURLOnDevice) {
            [self _launchURL:self.targetURL];
        }
    } else {
        [self fail];
    }
}

-(void)fail{
    if ([self.delegate respondsToSelector:@selector(loaderFailed:)]) {
        [self.delegate loaderFailed:self];
    }
    
    [self invalidate];
}


#pragma mark -
#pragma mark NSURLConnection
-(NSURLRequest *) connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response{
    self.targetURL = [request URL];
    if (++_totalRedirects < MAXIMUM_REDIRECTS) {
        return request;
    } else {
        PH_LOG(@"max redirects with URL %@", self.targetURL);
        [self finish];
        return nil;
    }
}

-(void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    PH_LOG(@"failing with error: %@", [error localizedDescription]);
    [self fail];
}

-(void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if ([httpResponse statusCode] < 300) {
        PH_LOG(@"finishing with URL %@", self.targetURL);
        [self finish];
    } else {
        PH_LOG(@"failing with URL %@", self.targetURL);
        [self fail];
    }
}

#pragma mark - hidden methods
-(void)_launchURL:(NSURL *)targetURL{
    [[UIApplication sharedApplication] openURL:targetURL];
}

@end
