#import <XCTest/XCTest.h>
#import <ZeroKit/ZeroKit-Swift.h>
#import "ZeroKitExampleTests-Swift.h"

#define kExpectationDefaultTimeout 90

@interface ObjcCompatibilityTests : XCTestCase
@property (strong, nonatomic) ZeroKitStack *zeroKitStack;
@end

@implementation ObjcCompatibilityTests

- (void)setUp {
    [super setUp];
    ZeroKit.logLevel = ZeroKitLogLevelWarning;
    [self resetZeroKit];
}

- (void)tearDown {
    self.zeroKitStack = nil;
    [super tearDown];
}

- (void)resetZeroKit {
    NSURL *configFile = [[NSBundle mainBundle] URLForResource:@"Config" withExtension:@"plist"];
    NSDictionary *configDict = [NSDictionary dictionaryWithContentsOfURL:configFile];
    
    NSURL *apiURL = [NSURL URLWithString:configDict[@"ZeroKitAPIBaseURL"]];
    NSString *clientID = configDict[@"ZeroKitClientId"];
    NSURL *backendURL = [NSURL URLWithString:configDict[@"ZeroKitAppBackend"]];
    
    ZeroKitConfig *config = [[ZeroKitConfig alloc] initWithApiBaseUrl:apiURL];
    ZeroKit *zeroKit = [[ZeroKit alloc] initWithConfig:config];
    
    Backend *backend = [[Backend alloc] initWithBackendBaseUrl:backendURL authorizationCallback:^(void (^credentialsCallback)(NSString * _Nullable, NSString * _Nullable, NSError * _Nullable)) {
        [zeroKit getIdentityTokensWithClientId:clientID completion:^(ZeroKitIdentityTokens * _Nullable tokens, NSError * _Nullable error) {
            credentialsCallback(tokens.authorizationCode, clientID, error);
        }];
    }];
    
    self.zeroKitStack = [[ZeroKitStack alloc] initWithZeroKit:zeroKit backend:backend];
}

#pragma mark - Convenience

- (TestUser *)registerUser {
    NSString * const username = [NSString stringWithFormat:@"test-user-%@", [NSUUID UUID].UUIDString];
    NSString * const profileData = @"{ \"autoValidate\": true }"; // User is automatically validated by the server
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Init registration"];
    
    NSString * __block userId = nil;
    NSString * __block regSessionId = nil;
    
    [self.zeroKitStack.backend initRegistrationWithUsername:username profileData:profileData completion:^(NSString * _Nullable aUserId, NSString * _Nullable aRegSessionId, NSError * _Nullable error) {
        XCTAssertNil(error);
        
        userId = aUserId;
        regSessionId = aRegSessionId;
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kExpectationDefaultTimeout handler:nil];
    
    expectation = [self expectationWithDescription:@"Registration"];
    
    NSString *__block regValidationVerifier = nil;
    NSString *password = @"Abc123";
    
    [self.zeroKitStack.zeroKit registerWithUserId:userId registrationId:regSessionId password:password completion:^(NSString * _Nullable aRegValidationVerifier, NSError * _Nullable error) {
        if (error) {
            XCTFail(@"Registration failed %@", error);
            return;
        }
        
        regValidationVerifier = aRegValidationVerifier;
        NSLog(@"Registration validation verifier: %@", regValidationVerifier);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kExpectationDefaultTimeout handler:nil];
    
    expectation = [self expectationWithDescription:@"User validation"];
    
    [self.zeroKitStack.backend finishRegistrationWithUserId:userId validationVerifier:regValidationVerifier completion:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        NSLog(@"Registration finished");
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kExpectationDefaultTimeout handler:nil];
    
    return [[TestUser alloc] initWithId:userId username:username password:password];
}

- (void)loginUser:(TestUser *)user {
    [self loginUser:user rememberMe:NO expectErrorCode:0];
}

- (void)loginUser:(TestUser *)user rememberMe:(BOOL)rememberMe {
    [self loginUser:user rememberMe:rememberMe expectErrorCode:0];
}

- (void)loginUser:(TestUser *)user rememberMe:(BOOL)rememberMe expectErrorCode:(ZeroKitError)errorCode {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Login"];
    [self.zeroKitStack.zeroKit loginWithUserId:user.id password:user.password rememberMe:rememberMe completion:^(NSError * _Nullable error) {
        if (error) {
            XCTAssertTrue(errorCode == error.code, @"Login failed with unexpected error: %@", error);
        } else {
            XCTAssertTrue(errorCode == 0, @"Login succeeded while expecting error code: %ld", (long)errorCode);
        }
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:kExpectationDefaultTimeout handler:nil];
}

- (void)loginByRememberMeWithUserId:(NSString *)userId {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Login by remember me"];
    
    [self.zeroKitStack.zeroKit loginByRememberMeWith:userId completion:^(NSError * _Nullable error) {
        if (error) {
            XCTFail(@"Failed to log in by remember me: %@", error);
        }
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kExpectationDefaultTimeout handler:nil];
}

- (void)logout {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Logout"];
    [self.zeroKitStack.backend forgetToken];
    [self.zeroKitStack.zeroKit logoutWithCompletion:^(NSError * _Nullable error) {
        if (error) {
            XCTFail(@"Logout failed %@", error);
        }
        
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:kExpectationDefaultTimeout handler:nil];
}

- (NSString *)whoAmI {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Who am I?"];
    NSString * __block userId = nil;
    [self.zeroKitStack.zeroKit whoAmIWithCompletion:^(NSString * _Nullable aUserId, NSError * _Nullable error) {
        if (error) {
            XCTFail(@"Who am I failed: %@", error);
        }
        userId = aUserId;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:kExpectationDefaultTimeout handler:nil];
    return userId;
}

- (NSString *)createTresor {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Tresor creation"];
    NSString * __block tresorId = nil;
    
    [self.zeroKitStack.zeroKit createTresorWithCompletion:^(NSString * _Nullable aTresorId, NSError * _Nullable error) {
        if (error) {
            XCTFail(@"Tresor creation failed: %@", error);
        }
        
        [self.zeroKitStack.backend createdTresorWithTresorId:aTresorId completion:^(NSError * _Nullable error) {
            XCTAssertNil(error);
            tresorId = aTresorId;
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:kExpectationDefaultTimeout handler:nil];
    return tresorId;
}

- (InvitationLinkPublicInfo *)infoForInvitationLink:(InvitationLink *)link {
    InvitationLinkPublicInfo * __block info = nil;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Getting link info"];
    NSString *secret = link.url.fragment;
    
    [self.zeroKitStack.zeroKit getInvitationLinkInfoWith:secret completion:^(InvitationLinkPublicInfo * _Nullable aInfo, NSError * _Nullable error) {
        if (error) {
            XCTFail("Failed to get invitation link info: %@", error);
        }
        
        info = aInfo;
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kExpectationDefaultTimeout handler:nil];
    
    return info;
}

- (TestUser *)changePasswordForUser:(TestUser *)user newPassword:(NSString *)newPassword {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Changing password"];
    
    [self.zeroKitStack.zeroKit changePasswordFor:user.id currentPassword:user.password newPassword:newPassword completion:^(NSError * _Nullable error) {
        if (error) {
            XCTFail(@"Failed to change password: %@", error);
        }
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kExpectationDefaultTimeout handler:nil];
    
    return [[TestUser alloc] initWithId:user.id username:user.username password:newPassword];
}

#pragma mark - Tests

- (void)testRegistration {
    [self registerUser];
}

- (void)testLoginLogout {
    TestUser *user = [self registerUser];
    [self loginUser:user];
    [self logout];
}

- (void)testLoginWithInvalidUser {
    TestUser *user = [[TestUser alloc] initWithId:@"InvalidUserID" username:@"DoesNotMatter" password:@"Password"];
    [self loginUser:user rememberMe:NO expectErrorCode:ZeroKitErrorInvalidUserId];
}

- (void)testLoginWithInvalidPassword {
    TestUser *user = [self registerUser];
    TestUser *invalidPwUser = [[TestUser alloc] initWithId:user.id username:user.username password:@"Invalid password"];
    [self loginUser:invalidPwUser rememberMe:NO expectErrorCode:ZeroKitErrorInvalidAuthorization];
}

- (void)testRememberMe {
    TestUser *user = [self registerUser];
    [self loginUser:user rememberMe:YES];
    
    [self resetZeroKit];
    
    [self loginByRememberMeWithUserId:user.id];
    
    [self logout];
}

- (void)testPasswordChange {
    TestUser *user = [self registerUser];
    [self loginUser:user];
    
    TestUser *userNewPassword = [self changePasswordForUser:user newPassword:@"Xyz987"];
    
    [self logout];
    
    [self loginUser:userNewPassword];
    [self logout];
}

- (void)testPasswordChangeRememberMe {
    TestUser *user = [self registerUser];
    [self loginUser:user rememberMe:YES];
    
    [self changePasswordForUser:user newPassword:@"Xyz987"];
    
    [self resetZeroKit];
    
    [self loginByRememberMeWithUserId:user.id];
    
    [self logout];
}

- (void)testWhoAmI {
    XCTAssertTrue([self whoAmI] == nil);
    
    TestUser *user = [self registerUser];
    [self loginUser:user];
    
    XCTAssertTrue([[self whoAmI] isEqualToString:user.id]);
    
    [self logout];
    
    XCTAssertTrue([self whoAmI] == nil);
}

- (void)testCreateTresor {
    TestUser *user = [self registerUser];
    [self loginUser:user];
    NSString *tresorId = [self createTresor];
    XCTAssertTrue(tresorId.length > 0);
    [self logout];
}

- (void)testTextEncryption {
    TestUser *user = [self registerUser];
    [self loginUser:user];
    NSString *tresorId = [self createTresor];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Text encryption"];
    
    NSString *plainText = @"Encrypting this.";
    
    [self.zeroKitStack.zeroKit encryptWithPlainText:plainText inTresor:tresorId completion:^(NSString * _Nullable cipherText, NSError * _Nullable error) {
        if (error) {
            XCTFail(@"Text encryption failed: %@", error);
        }
        
        [self.zeroKitStack.zeroKit decryptWithCipherText:cipherText completion:^(NSString * _Nullable aPlainText, NSError * _Nullable error) {
            if (error) {
                XCTFail(@"Text decryption failed: %@", error);
            }
            
            XCTAssertTrue([aPlainText isEqualToString:plainText]);
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:kExpectationDefaultTimeout handler:nil];
}

- (void)testDataEncryption {
    TestUser *user = [self registerUser];
    [self loginUser:user];
    NSString *tresorId = [self createTresor];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Text encryption"];
    
    NSData *plainData = [@"Encrypting this." dataUsingEncoding:NSUTF8StringEncoding];
    
    [self.zeroKitStack.zeroKit encryptWithPlainData:plainData inTresor:tresorId completion:^(NSData * _Nullable cipherData, NSError * _Nullable error) {
        if (error) {
            XCTFail(@"Data encryption failed: %@", error);
        }
        
        [self.zeroKitStack.zeroKit decryptWithCipherData:cipherData completion:^(NSData * _Nullable aPlainData, NSError * _Nullable error) {
            if (error) {
                XCTFail(@"Data decryption failed: %@", error);
            }
            
            XCTAssertTrue([aPlainData isEqual:plainData]);
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:kExpectationDefaultTimeout handler:nil];
}

- (void)testTresorSharingAndKick {
    TestUser *owner = [self registerUser];
    TestUser *invitee = [self registerUser];
    
    [self loginUser:owner];
    
    NSString *tresorId = [self createTresor];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Tresor sharing"];
    
    [self.zeroKitStack.zeroKit shareWithTresorWithId:tresorId withUser:invitee.id completion:^(NSString * _Nullable operationId, NSError * _Nullable error) {
        if (error) {
            XCTFail(@"Tresor sharing failed: %@", error);
        }
        
        [self.zeroKitStack.backend sharedTresorWithOperationId:operationId completion:^(NSError * _Nullable error) {
            XCTAssertNil(error);
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:kExpectationDefaultTimeout handler:nil];
    
    expectation = [self expectationWithDescription:@"Kicking user"];
    
    [self.zeroKitStack.zeroKit kickWithUserWithId:invitee.id fromTresor:tresorId completion:^(NSString * _Nullable operationId, NSError * _Nullable error) {
        if (error) {
            XCTFail(@"Kicking user failed: %@", error);
        }
        
        [self.zeroKitStack.backend kickedUserWithOperationId:operationId completion:^(NSError * _Nullable error) {
            XCTAssertNil(error);
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:kExpectationDefaultTimeout handler:nil];
}

- (void)testInvitationLinkNoPassword {
    TestUser *owner = [self registerUser];
    TestUser *invitee = [self registerUser];
    
    [self loginUser:owner];
    
    NSString *tresorId = [self createTresor];
    
    NSURL *baseUrl = [NSURL URLWithString:@"https://tresorit.io/"];
    NSString *message = @"This is the message";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Creating link without password"];
    
    InvitationLink * __block link = nil;
    
    [self.zeroKitStack.zeroKit createInvitationLinkWithoutPasswordWith:baseUrl forTresor:tresorId withMessage:message completion:^(InvitationLink * _Nullable aLink, NSError * _Nullable error) {
        if (error) {
            XCTFail(@"Failed to create invitation link without password: %@", error);
        }
        
        [self.zeroKitStack.backend createdInvitationLinkWithOperationId:aLink.id completion:^(NSError * _Nullable error) {
            XCTAssertNil(error);
            link = aLink;
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:kExpectationDefaultTimeout handler:nil];
    
    [self logout];
    
    [self loginUser:invitee];
    
    InvitationLinkPublicInfo *info = [self infoForInvitationLink:link];
    
    XCTAssertTrue([info.creatorUserId isEqualToString:owner.id]);
    XCTAssertTrue([info.message isEqualToString:message]);
    XCTAssertFalse(info.isPasswordProtected);

    expectation = [self expectationWithDescription:@"Accepting link without password"];
    
    [self.zeroKitStack.zeroKit acceptInvitationLinkWithoutPasswordWith:info.token completion:^(NSString * _Nullable operationId, NSError * _Nullable error) {
        if (error) {
            XCTFail(@"Failed to accept invitation link without password: %@", error);
        }
        
        [self.zeroKitStack.backend acceptedInvitationLinkWithOperationId:operationId completion:^(NSError * _Nullable error) {
            XCTAssertNil(error);
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:kExpectationDefaultTimeout handler:nil];
}

- (void)testInvitationLink {
    TestUser *owner = [self registerUser];
    TestUser *invitee = [self registerUser];
    
    [self loginUser:owner];
    
    NSString *tresorId = [self createTresor];
    
    NSURL *baseUrl = [NSURL URLWithString:@"https://tresorit.io/"];
    NSString *message = @"This is the message";
    NSString *password = @"Password1.";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Creating link without password"];
    
    InvitationLink * __block link = nil;
    
    [self.zeroKitStack.zeroKit createInvitationLinkWith:baseUrl forTresor:tresorId withMessage:message password:password completion:^(InvitationLink * _Nullable aLink, NSError * _Nullable error) {
        if (error) {
            XCTFail(@"Failed to create invitation link without password: %@", error);
        }
        
        [self.zeroKitStack.backend createdInvitationLinkWithOperationId:aLink.id completion:^(NSError * _Nullable error) {
            XCTAssertNil(error);
            link = aLink;
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:kExpectationDefaultTimeout handler:nil];
    
    [self logout];
    
    [self loginUser:invitee];
    
    InvitationLinkPublicInfo *info = [self infoForInvitationLink:link];
    
    XCTAssertTrue([info.creatorUserId isEqualToString:owner.id]);
    XCTAssertTrue([info.message isEqualToString:message]);
    XCTAssertTrue(info.isPasswordProtected);
    
    expectation = [self expectationWithDescription:@"Accepting link without password"];
    
    [self.zeroKitStack.zeroKit acceptInvitationLinkWith:info.token password:password completion:^(NSString * _Nullable operationId, NSError * _Nullable error) {
        if (error) {
            XCTFail(@"Failed to accept invitation link without password: %@", error);
        }
        
        [self.zeroKitStack.backend acceptedInvitationLinkWithOperationId:operationId completion:^(NSError * _Nullable error) {
            XCTAssertNil(error);
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:kExpectationDefaultTimeout handler:nil];
}

- (void)testPasswordStrength {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Getting password strenth"];
    
    PasswordStrength *__block s = nil;
    
    [self.zeroKitStack.zeroKit passwordStrengthWithPassword:@"vkntF2e@FBW7" completion:^(PasswordStrength * _Nullable strength, NSError * _Nullable error) {
        XCTAssertNil(error);
        s = strength;
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kExpectationDefaultTimeout handler:nil];
    
    XCTAssertNotNil(s);
}

- (void)testGetIdentityToken {
    TestUser *user = [self registerUser];
    [self loginUser:user];
    
    NSString *clientId = @"{Put your client ID here}";
    XCTestExpectation *expectation = [self expectationWithDescription:@"IDP test"];
    
    [self.zeroKitStack.zeroKit getIdentityTokensWithClientId:clientId completion:^(ZeroKitIdentityTokens * _Nullable tokens, NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertNotNil(tokens);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kExpectationDefaultTimeout handler:nil];
    
    [self logout];
}

@end
