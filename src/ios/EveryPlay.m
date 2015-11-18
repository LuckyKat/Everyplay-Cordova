#import "EveryPlay.h"


@implementation EveryPlay

- (void)pluginInitialize
{

}

- (void)everyplayShown
{
    NSLog(@"everyplay shown");
}

- (void)everyplayHidden
{
    NSLog(@"everyplay hidden");
}

- (void)init:(CDVInvokedUrlCommand*)command
{
    NSLog(@"plugin initialize");
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        NSString* callbackId = [command callbackId];

        NSString* clientId = [[command arguments] objectAtIndex:0];
        NSString* clientSecret = [[command arguments] objectAtIndex:1];

        [Everyplay setClientId:clientId clientSecret:clientSecret redirectURI:@"https://m.everyplay.com/auth"];
        
        // Tell Everyplay to use our rootViewController for presenting views and for delegate calls.
        [Everyplay initWithDelegate:self andParentViewController:self.viewController];

        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    }];

}

- (void)loggedIn:(CDVInvokedUrlCommand*)command
{
    
    NSLog(@"loggedIn");
    [self.commandDelegate runInBackground:^{
        NSString* callbackId = [command callbackId];
        
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK messageAsBool:([Everyplay account] != nil)];
        
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    }];
}

- (void) requestAccess:(CDVInvokedUrlCommand*)command
{
    NSLog(@"request access");
    [self.commandDelegate runInBackground:^{
        NSString* callbackId = [command callbackId];
        
        [Everyplay requestAccessWithCompletionHandler:^(NSError *error) {
            CDVPluginResult* result = [CDVPluginResult
                                       resultWithStatus:CDVCommandStatus_OK messageAsBool:(error == nil)];
            
            [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        }];
    }];
}

- (void)removeAccess:(CDVInvokedUrlCommand*)command
{
    NSLog(@"remove access");
    [self.commandDelegate runInBackground:^{
        [Everyplay removeAccess];
        
        NSString* callbackId = [command callbackId];
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK];
        
        
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    }];
}

/*
 {
 acl =     {
 "has_access_to" =         (
 update,
 destroy,
 read,
 create
 );
 };
 "acl_roles" =     (
 );
 admin = 0;
 "authentication_methods" =     (
 );
 "avatar_url" = "https://www.everyplay.com/assets/img/icon-default-avatar.png";
 "avatar_url_small" = "https://www.everyplay.com/assets/img/icon-default-avatar-small.png";
 "can_comment" = 1;
 "comment_count" = 0;
 "cover_url" = "https://www.everyplay.com/assets/img/icon-default-cover.jpeg";
 "cover_url_small" = "https://www.everyplay.com/assets/img/icon-default-cover.jpeg";
 "created_at" = "2015-06-16T19:48:03.129Z";
 "date_of_birth" = "1937-01-31T00:00:00.000Z";
 "developer_data" =     {
 };
 "followers_count" = 0;
 "followings_count" = 0;
 "friend_request_sent" = 0;
 "games_count" = 0;
 "groups_count" = 2;
 hidden = 0;
 id = 28049696;
 "is_friends" = 0;
 "password_set" = 0;
 permalink = player28049696;
 "permalink_url" = "https://m.everyplay.com/player28049696";
 "private_video_count" = 0;
 "public_roles" =     (
 );
 "public_video_count" = 0;
 "receive_newsletter" = 1;
 settings =     {
 };
 state =     {
 };
 status = limited;
 subscriptions =     {
 comments = on;
 followers = on;
 mentions = on;
 newsletter = on;
 uploads = on;
 };
 "total_comment_count" = 0;
 "unread_notifications_since" = "2015-06-16T19:48:03.129Z";
 uri = "https://api.everyplay.com/users/28049696";
 "user_followed" = 0;
 "user_following" = 0;
 username = Player28049696;
 verified = 0;
 "video_count" = 0;
 }
 
 */
- (void)loadUser:(CDVInvokedUrlCommand*)command
{
    NSLog(@"load user");
    [self.commandDelegate runInBackground:^{
        NSString* callbackId = [command callbackId];
        
        EveryplayAccount *account = [Everyplay account];
        if(account != nil) {
            // Load the player info from server
            [account loadUserWithCompletionHandler:^(NSError *error, NSDictionary *data) {
                if (error) {
                    CDVPluginResult* result = [CDVPluginResult
                                               resultWithStatus:CDVCommandStatus_ERROR
                                               messageAsString:error.description];
                    
                    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
                } else {
                    NSLog(@"%@", data);
                    CDVPluginResult* result = [CDVPluginResult
                                               resultWithStatus:CDVCommandStatus_OK
                                               messageAsDictionary:data];
                    
                    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
                }
                
            }];
        } else {
            CDVPluginResult* result = [CDVPluginResult
                                       resultWithStatus:CDVCommandStatus_ERROR
                                       messageAsString:@"Not logged in yet"];
            
            [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        }
    }];
}

- (void)loadVideos:(CDVInvokedUrlCommand*)command
{
    NSLog(@"load videos");
    NSString* callbackId = [command callbackId];
    if ([Everyplay account] != nil) {
        NSURL *resource = [NSURL URLWithString:@"https://api.everyplay.com/videos"];
        [EveryplayRequest performMethod:EveryplayRequestMethodGET
                             onResource:resource
                        usingParameters:@{@"order":@"popularity"}
                            withAccount:[Everyplay account]
                 sendingProgressHandler:nil
                        responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error) {
                            if(error == nil) {
                                id parsed = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
                                if(parsed == nil) {
                                    NSLog(@"Unable to parse request data");
                                    if (error) {
                                        [self.commandDelegate runInBackground:^{
                                            CDVPluginResult* result = [CDVPluginResult
                                                                       resultWithStatus:CDVCommandStatus_ERROR
                                                                       messageAsString:@"Unable to parse request data"];
                                            
                                            [self.commandDelegate sendPluginResult:result callbackId:callbackId];
                                        }];
                                    }
                                } else if([parsed isKindOfClass:[NSArray class]]) {
                                    NSLog(@"Videos loaded");
                                    [self.commandDelegate runInBackground:^{
                                        CDVPluginResult* result = [CDVPluginResult
                                                                   resultWithStatus:CDVCommandStatus_OK
                                                                   messageAsArray:parsed];
                                        
                                        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
                                    }];
                                }
                            } else {
                                CDVPluginResult* result = [CDVPluginResult
                                                           resultWithStatus:CDVCommandStatus_ERROR
                                                           messageAsString:error.description];
                                
                                [self.commandDelegate sendPluginResult:result callbackId:callbackId];
                            }
                        }];
    } else {
        [self.commandDelegate runInBackground:^{
            CDVPluginResult* result = [CDVPluginResult
                                       resultWithStatus:CDVCommandStatus_ERROR
                                       messageAsString:@"Not logged in yet"];
            
            [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        }];
    }
}

- (void)playVideo:(CDVInvokedUrlCommand*)command
{
    NSLog(@"play video");
    NSString* callbackId = [command callbackId];
    NSDictionary *video = [[command arguments] objectAtIndex:0];
    if (video!=nil) {
        [[Everyplay sharedInstance] playVideoWithDictionary:video];
    }
    
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK];
    
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    }];
}

- (void)showEveryplay:(CDVInvokedUrlCommand*)command
{
    NSLog(@"show Everyplay");
    [self.commandDelegate runInBackground:^{
    [[Everyplay sharedInstance] showEveryplay];
    }];
}

- (void)showEveryplaySharingModal:(CDVInvokedUrlCommand*)command
{
    NSLog(@"show Everyplay Sharing modal");
    [self.commandDelegate runInBackground:^{
        [[Everyplay sharedInstance] showEveryplaySharingModal];
    }];
}

- (void)isRecording:(CDVInvokedUrlCommand*)command
{
    NSLog(@"is recording %@", [[[Everyplay sharedInstance] capture] isRecording] ? @"YES" : @"NO");
    [self.commandDelegate runInBackground:^{
        NSString* callbackId = [command callbackId];
        
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK
                                   messageAsBool:[[[Everyplay sharedInstance] capture] isRecording]];
        
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    }];
}

- (void)isRecordingSupported:(CDVInvokedUrlCommand*)command
{
    NSLog(@"is recording supported %@", [[[Everyplay sharedInstance] capture] isRecordingSupported] ? @"YES" : @"NO");
    [self.commandDelegate runInBackground:^{
        NSString* callbackId = [command callbackId];
        
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK
                                   messageAsBool:[[[Everyplay sharedInstance] capture] isRecordingSupported]];
        
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    }];
}

- (void)startRecording:(CDVInvokedUrlCommand*)command;
{
    NSLog(@"start recording");
    [self.commandDelegate runInBackground:^{
        [[[Everyplay sharedInstance] capture] startRecording];
    }];
}

- (void)stopRecording:(CDVInvokedUrlCommand*)command;
{
    NSLog(@"stop recording");
    [self.commandDelegate runInBackground:^{
        [[[Everyplay sharedInstance] capture] stopRecording];
    }];
}

- (void)playLastRecording:(CDVInvokedUrlCommand*)command
{
    NSLog(@"play last recording");
    [self.commandDelegate runInBackground:^{
        [[Everyplay sharedInstance] playLastRecording];
    }];
}

- (void)snapshotRenderbuffer:(CDVInvokedUrlCommand*)command;
{
    NSLog(@"snapshot Render buffer");
    [self.commandDelegate runInBackground:^{
        [[[Everyplay sharedInstance] capture] snapshotRenderbuffer];
    }];
}

- (void)resumeRecording:(CDVInvokedUrlCommand*)command
{
    NSLog(@"resume recording");
    [self.commandDelegate runInBackground:^{
        [[[Everyplay sharedInstance] capture] resumeRecording];
    }];   
}

- (void)pauseRecording:(CDVInvokedUrlCommand*)command
{
    NSLog(@"pause recording");
    [self.commandDelegate runInBackground:^{
        [[[Everyplay sharedInstance] capture] pauseRecording];
    }];  
}

- (void)isPaused:(CDVInvokedUrlCommand*)command
{
    NSLog(@"is pause");
    [self.commandDelegate runInBackground:^{
        NSString* callbackId = [command callbackId];
        
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK messageAsBool:([[[Everyplay sharedInstance] capture] isPaused])];
        
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    }];
}

- (void)isDisableSingleCoreDevices:(CDVInvokedUrlCommand*)command
{
    NSLog(@"is Disable Single Core Devices");
    [self.commandDelegate runInBackground:^{
        NSString* callbackId = [command callbackId];
        
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK messageAsBool:([[[Everyplay sharedInstance] capture] disableSingleCoreDevices])];
        
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    }];
}

- (void)setDisableSingleCoreDevices:(CDVInvokedUrlCommand*)command
{
    NSLog(@"set disable Single Core Devices");
    [self.commandDelegate runInBackground:^{
        BOOL isDisabled = [[command arguments] objectAtIndex:0];
        [[[Everyplay sharedInstance] capture] setDisableSingleCoreDevices:isDisabled];
    }];
}

- (void)getLowMemoryDevice:(CDVInvokedUrlCommand*)command
{
    NSLog(@"get Low Memory Device");
    [self.commandDelegate runInBackground:^{
        NSString* callbackId = [command callbackId];
        
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK messageAsBool:([[[Everyplay sharedInstance] capture] lowMemoryDevice])];
        
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    }];
}

- (void)setLowMemoryDevice:(CDVInvokedUrlCommand*)command
{
    NSLog(@"set Low Memory Device");
    [self.commandDelegate runInBackground:^{
        BOOL isOptimize = [[command arguments] objectAtIndex:0];
        [[[Everyplay sharedInstance] capture] setLowMemoryDevice:isOptimize];
    }];
}

- (void)getMaxRecordingMinutesLength:(CDVInvokedUrlCommand*)command
{
    NSLog(@"get Max Recording Minutes Length");
    [self.commandDelegate runInBackground:^{
        NSString* callbackId = [command callbackId];
        
        NSInteger minutes = [[[Everyplay sharedInstance] capture] maxRecordingMinutesLength];
        CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK messageAsInt:((int)minutes)];
        
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    }];
}

- (void)setMaxRecordingMinutesLength:(CDVInvokedUrlCommand*)command
{
    NSLog(@"set Max Recording Minutes Length");
    [self.commandDelegate runInBackground:^{
        NSNumber *minutes = [[command arguments] objectAtIndex:0];
        [[[Everyplay sharedInstance] capture] setMaxRecordingMinutesLength:[minutes integerValue]];
    }];
}

- (void)mergeSessionDeveloperData:(CDVInvokedUrlCommand*)command
{
    NSLog(@"merge Session Developer Data");
    [self.commandDelegate runInBackground:^{
        NSDictionary *data = [[command arguments] objectAtIndex:0];
        [[Everyplay sharedInstance] mergeSessionDeveloperData:data];
    }];   
}

@end