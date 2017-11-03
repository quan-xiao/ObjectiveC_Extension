//
//  VMMWebView.m
//  ObjectiveC_Extension
//
//  Created by Vitor Marques de Miranda on 30/10/2017.
//  Copyright © 2017 VitorMM. All rights reserved.
//

#import "VMMWebView.h"

#import "NSColor+Extension.h"
#import "NSString+Extension.h"

#import "NSComputerInformation.h"

@implementation VMMWebViewNavigationBar
-(void)setBackgroundColor:(NSColor*)color
{
    _backgroundColor = color;
    [self needsDisplay];
}
-(void)drawRect:(NSRect)dirtyRect
{
    if (_backgroundColor)
    {
        [_backgroundColor setFill];
        NSRectFillUsingOperation(dirtyRect, NSCompositeSourceOver);
    }
    
    [super drawRect:dirtyRect];
}
@end

@implementation VMMWebView

-(void)setLastAccessedUrl:(NSURL*)lastAccessedUrl
{
    _lastAccessedUrl = lastAccessedUrl;
    
    if (self.hasNavigationBar)
    {
        [_navigationBar.addressBarField setStringValue:_lastAccessedUrl.absoluteString];
    }
}

// WebView needed delegates
-(WebView *)webView:(WebView *)sender createWebViewWithRequest:(NSURLRequest *)request
{
    self.lastAccessedUrl = request.URL;
    return sender;
}
-(void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request
         frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener
{
    self.lastAccessedUrl = [(WebView*)self.webView mainFrame].dataSource.request.URL;
    
    NSURL *urlToOpenUrl = actionInformation[WebActionOriginalURLKey];
    if (![self shouldLoadUrl:urlToOpenUrl withHttpBody:request.HTTPBody]) return;
    
    [listener use];
}

// WKWebView needed delegates
- (id)webView:(id)webView createWebViewWithConfiguration:(id)configuration forNavigationAction:(id)navigationAction windowFeatures:(id)windowFeatures
{
    self.lastAccessedUrl = ((WKNavigationAction *)navigationAction).request.URL;
    if (![self shouldLoadUrl:_lastAccessedUrl withHttpBody:((WKNavigationAction *)navigationAction).request.HTTPBody]) return nil;
    
    [self loadURL:_lastAccessedUrl];
    return nil;
}
- (void)webView:(id)webView decidePolicyForNavigationAction:(id)navigationAction decisionHandler:(void (^)(NSInteger))decisionHandler
{
    NSURL *urlToOpenUrl = ((WKNavigationAction *)navigationAction).request.URL;
    if (![self shouldLoadUrl:urlToOpenUrl withHttpBody:((WKNavigationAction *)navigationAction).request.HTTPBody])
    {
        decisionHandler(WKNavigationActionPolicyCancel);
    }
    else
    {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}
- (void)webView:(id)webView didCommitNavigation:(id)navigation
{
    self.lastAccessedUrl = [(WKWebView*)self.webView URL];
}

// Initialization private methods
-(void)initializeWebView
{
    _usingWkWebView = IsWKWebViewAvailable;
    
    if (_usingWkWebView)
    {
        _webView = [[WKWebView alloc] init];
        WKWebView* webView = (WKWebView*)_webView;
        
        webView.UIDelegate = (id<WKUIDelegate>)self;
        webView.navigationDelegate = (id<WKNavigationDelegate>)self;
        
        [webView setValue:@FALSE forKey:@"opaque"];
        
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wundeclared-selector"
        BOOL setDrawsBackgroundExists = [webView respondsToSelector:@selector(_setDrawsBackground:)];
#pragma GCC diagnostic pop
        
        if (setDrawsBackgroundExists)
        {
            [webView setValue:@FALSE forKey:@"drawsBackground"];
        }
        else
        {
            [webView setValue:@TRUE  forKey:@"drawsTransparentBackground"];
        }
    }
    else
    {
        _webView = [[WebView alloc] init];
        WebView* webView = (WebView*)_webView;
        
        webView.UIDelegate = (id<WebUIDelegate>)self;
        webView.policyDelegate = (id<WebPolicyDelegate>)self;
        webView.frameLoadDelegate = (id<WebFrameLoadDelegate>)self;
        
        webView.shouldUpdateWhileOffscreen = false;
        
        [webView setValue:@FALSE forKey:@"opaque"];
        [webView setValue:@FALSE forKey:@"drawsBackground"];
    }
    
    [self addSubview:_webView];
    [_webView setAutoresizingMask:NSViewMinYMargin|NSViewMaxXMargin|NSViewMinXMargin|NSViewWidthSizable|NSViewHeightSizable];
}
-(void)initializeNavigationBarWithHeight:(CGFloat)navigationBarHeight
{
    _navigationBar = [[VMMWebViewNavigationBar alloc] init];
    
    [self addSubview:_navigationBar];
    [_navigationBar setAutoresizingMask:NSViewMinYMargin|NSViewMaxXMargin|NSViewMinXMargin|NSViewWidthSizable];
    [_navigationBar setBackgroundColor:self.navigationBarColor];
    
    NSFont* buttonTextFont = self.navigationBarButtonsTextFont;
    if (buttonTextFont)
    {
        buttonTextFont = [NSFont fontWithDescriptor:buttonTextFont.fontDescriptor size:self.navigationBarButtonsTextSize];
    }
    else
    {
        buttonTextFont = [NSFont systemFontOfSize:self.navigationBarButtonsTextSize];
    }
    
    NSFont* addressTextFont = self.navigationBarAddressFieldTextFont;
    if (addressTextFont)
    {
        addressTextFont = [NSFont fontWithDescriptor:addressTextFont.fontDescriptor size:self.navigationBarAddressFieldTextSize];
    }
    else
    {
        addressTextFont = [NSFont systemFontOfSize:self.navigationBarAddressFieldTextSize];
    }
    
    CGFloat fullWidth = _navigationBar.frame.size.width;
    CGFloat leftMargin = self.navigationBarLeftMargin;
    
    _navigationBar.addressBarField = [[NSTextField alloc] init];
    _navigationBar.refreshButton = [[NSButton alloc] init];
    [_navigationBar addSubview:_navigationBar.addressBarField];
    [_navigationBar addSubview:_navigationBar.refreshButton];
    
    
    [_navigationBar.addressBarField setAutoresizingMask:NSViewWidthSizable];
    [_navigationBar.addressBarField setBordered:NO];
    [_navigationBar.addressBarField setEditable:NO];
    [_navigationBar.addressBarField setBackgroundColor:[NSColor clearColor]];
    [_navigationBar.addressBarField setFont:addressTextFont];
    [_navigationBar.addressBarField setStringValue:@"Tj"];
    CGFloat addressMaxHeight = _navigationBar.addressBarField.attributedStringValue.size.height;
    [_navigationBar.addressBarField setFrame:NSMakeRect(leftMargin, (navigationBarHeight - addressMaxHeight)/2,
                                                        fullWidth - navigationBarHeight - leftMargin, addressMaxHeight)];
    [_navigationBar.addressBarField setStringValue:@""];
    
    
    [_navigationBar.refreshButton.cell setHighlightsBy:NSNoCellMask];
    [_navigationBar.refreshButton setBordered:NO];
    [_navigationBar.refreshButton setTitle:@"⟳"];
    [_navigationBar.refreshButton setFont:buttonTextFont];
    [_navigationBar.refreshButton setTarget:self];
    [_navigationBar.refreshButton setAction:@selector(refreshButtonPressed:)];
    [_navigationBar.refreshButton setAutoresizingMask:NSViewMaxYMargin|NSViewMinYMargin|NSViewMinXMargin];
    [_navigationBar.refreshButton setFrame:NSMakeRect(fullWidth - navigationBarHeight, 0, navigationBarHeight, navigationBarHeight)];
}
-(void)reloadWebViewIfNeeded
{
    @synchronized(_webView)
    {
        BOOL hasNavigationBar = self.hasNavigationBar;
        
        CGFloat width = self.frame.size.width;
        CGFloat navigationBarHeight = 0;
        
        if (hasNavigationBar)
        {
            navigationBarHeight = self.navigationBarHeight;
            if (!_navigationBar) [self initializeNavigationBarWithHeight:navigationBarHeight];
        }
        
        if (!_webView)
        {
            [self initializeWebView];
        }
        
        CGFloat webViewHeight = self.frame.size.height - navigationBarHeight;
        
        if (hasNavigationBar)
        {
            [_navigationBar setFrame:NSMakeRect(0, webViewHeight, width, navigationBarHeight)];
        }
        
        [_webView setFrame:NSMakeRect(0, 0, width, webViewHeight)];
    }
}

// Private functions
-(IBAction)refreshButtonPressed:(id)sender
{
    [self loadURL:_lastAccessedUrl];
}

// Private functions that may be overrided
-(BOOL)hasNavigationBar
{
    return _urlLoaded;
}
-(CGFloat)navigationBarLeftMargin
{
    return 20.0;
}
-(CGFloat)navigationBarHeight
{
    return 45.0;
}
-(NSColor*)navigationBarColor
{
    return RGB(209, 207, 209);
}
-(NSFont*)navigationBarAddressFieldTextFont
{
    return nil;
}
-(CGFloat)navigationBarAddressFieldTextSize
{
    return 15.0;
}
-(NSFont*)navigationBarButtonsTextFont
{
    return nil;
}
-(CGFloat)navigationBarButtonsTextSize
{
    return 30.0;
}
-(BOOL)shouldLoadUrl:(NSURL*)urlToOpenUrl withHttpBody:(NSData*)httpBody
{
    return YES;
}
-(NSString*)errorHTMLWithMessage:(NSString*)message
{
    // TODO: The text is not centered since a Sierra update
    NSString* result;
    
    @autoreleasepool
    {
        // BODY related values
        NSString* bodyStyle = @"margin: 0; padding: 0; height: 100%%; width: 100%%;";
        NSString* avoidRightClickVar = @"oncontextmenu=\"return false;\"";
        NSString* openBody = [NSString stringWithFormat:@"<BODY bgcolor=\"black\" style=\"%@\" %@>",bodyStyle,avoidRightClickVar];
        
        // DIV related values
        NSString* fontStyleVars = @"color:#FFFFFF; font-family: 'Helvetica Neue', Helvetica;";
        NSString* centeredStyleVars = @"position: absolute; top: 50%%; left: 50%%; transform: translateX(-50%%) translateY(-50%%); -webkit-transform: translate(-50%%, -50%%); -ms-transform: translateX(-50%%) translateY(-50%%); -webkit-transform: translateX(-50%%) translateY(-50%%); -moz-transform: translateX(-50%%) translateY(-50%%); -o-transform: translateX(-50%%) translateY(-50%%);";
        NSString* unselectableStyleVars = @"-webkit-touch-callout: none; -webkit-user-select: none; -khtml-user-select: none; -moz-user-select: none; -ms-user-select: none; user-select: none;";
        NSString* div = [NSString stringWithFormat:@"<div style=\"%@ %@ %@\">%@</div>",unselectableStyleVars,centeredStyleVars,fontStyleVars,message];
        
        result = [NSString stringWithFormat:@"<HTML><HEAD></HEAD>%@<center>%@</center></BODY></HTML>",openBody,div];
    }
    
    return result;
}

// Public functions
-(void)showErrorMessage:(NSString*)errorMessage
{
    [self reloadWebViewIfNeeded];
    [self loadHTMLString:[self errorHTMLWithMessage:[errorMessage uppercaseString]]];
}
-(BOOL)loadURL:(NSURL*)url
{
    if (!_usingWkWebView && [url.absoluteString contains:@"://www.youtube.com/v/"])
    {
        NSString* mainFolderPluginPath = @"/Library/Internet Plug-Ins/Flash Player.plugin";
        NSString* userFolderPluginPath = [NSString stringWithFormat:@"%@%@",NSHomeDirectory(),mainFolderPluginPath];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:mainFolderPluginPath] &&
            ![[NSFileManager defaultManager] fileExistsAtPath:userFolderPluginPath])
        {
            [self showErrorMessage:NSLocalizedString(@"You need Flash Player in order to watch YouTube videos in your macOS version",nil)];
            return NO;
        }
    }
    
    _urlLoaded = true;
    [self reloadWebViewIfNeeded];
    self.lastAccessedUrl = url;
    
    if (_usingWkWebView)
    {
        [(WKWebView*)self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    }
    else
    {
        [((WebView*)self.webView).mainFrame loadRequest:[NSURLRequest requestWithURL:url]];
    }
    
    return YES;
}
-(BOOL)loadURLWithString:(NSString*)website
{
    if (![website isAValidURL])
    {
        [self showErrorMessage:NSLocalizedString(@"Invalid URL provided",nil)];
        return NO;
    }
    
    return [self loadURL:[NSURL URLWithString:website]];
}
-(void)loadHTMLString:(NSString*)htmlPage
{
    _urlLoaded = false;
    [self reloadWebViewIfNeeded];
    
    if (_usingWkWebView)
    {
        [(WKWebView*)self.webView loadHTMLString:htmlPage baseURL:[NSURL URLWithString:@"about:blank"]];
    }
    else
    {
        [((WebView*)self.webView).mainFrame loadHTMLString:htmlPage baseURL:[NSURL URLWithString:@"about:blank"]];
    }
}
-(void)loadEmptyPage
{
    [self loadHTMLString:@""];
}

@end
