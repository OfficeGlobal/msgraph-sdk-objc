//
// Copyright (c) Microsoft Corporation. All Rights Reserved. Licensed under the MIT License. See License in the project root for license information.
//

#import <XCTest/XCTest.h>
#import "MSGraphCoreSDKTests.h"


@interface MSURLSessionTask()

- (void)setRequest:(NSMutableURLRequest *)request;
- (void)setInnerTask:(NSURLSessionTask *)innerTask;

@end

@interface MSURLSessionTaskTests : MSGraphCoreSDKTests

@property (nonatomic,retain) MSURLSessionManager * sessionManager;
@end

@implementation MSURLSessionTaskTests

- (void)setUp {
    [super setUp];

    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    self.sessionManager = [[MSURLSessionManager alloc] initWithSessionConfiguration:config];

}

- (void)tearDown {
    self.sessionManager = nil;
    [super tearDown];
}
- (void)testInitFailsWithNilClient{
    XCTAssertThrows([[MSURLSessionTask alloc] initWithRequest:[NSMutableURLRequest requestWithURL:self.testBaseURL] client:nil]);
}
- (void)testInitFailsWithNilRequest{
    XCTAssertThrows([[MSURLSessionTask alloc] initWithRequest:nil client:self.mockClient]);
}

- (void)testInitMSURLSessionTaskState{
    MSURLSessionTask *msURLSessionTask= [[MSURLSessionTask alloc] initWithRequest:self.requestForMock client:self.mockClient];
    XCTAssertEqual(msURLSessionTask.client, self.mockClient);
}

- (void)testSetInnerTask{
    MSURLSessionTask *msSessionTask = [[MSURLSessionTask alloc] initWithRequest:self.requestForMock client:self.mockClient];

    NSURLSessionTask *nsSessionTask = [self.mockHttpProvider dataTaskWithRequest:self.requestForMock completionHandler:nil];

    [msSessionTask setInnerTask:nsSessionTask];

    XCTAssertEqual(nsSessionTask, msSessionTask.innerTask);
    
}

- (void)testSetInnerTaskForCancelledTask{
    MSURLSessionTask *msSessionTask = [[MSURLSessionTask alloc] initWithRequest:self.requestForMock client:self.mockClient];
    [msSessionTask cancel];

    XCTestExpectation *testExpectation = [[XCTestExpectation alloc] initWithDescription:@"Waiting for cancellation of request."];

    MSDataCompletionHandler requestCompletion = ^(NSData *data, NSURLResponse * _Nullable response, NSError * _Nullable error){

        [self completionBlockCodeInvoked];
        XCTAssertNotNil(error);
        XCTAssertNil(response);
        XCTAssertNil(data);
        BOOL isCancelled = [error.localizedDescription isEqualToString:@"cancelled"];
        XCTAssertTrue(isCancelled);
        [testExpectation fulfill];
    };

    NSURLSessionTask *nsSessionTask = [self.sessionManager dataTaskWithRequest:self.requestForMock completionHandler:requestCompletion];

    [msSessionTask setInnerTask:nsSessionTask];
    [self waitForExpectations:@[testExpectation] timeout:5.0];
    [self checkCompletionBlockCodeInvoked];
    
}

- (void)testTaskCancellation{
    MSURLSessionTask *msSessionTask = [[MSURLSessionTask alloc] initWithRequest:self.requestForMock client:self.mockClient];

    XCTestExpectation *testExpectation = [[XCTestExpectation alloc] initWithDescription:@"Waiting for cancellation of request."];

    MSDataCompletionHandler requestCompletion = ^(NSData *data, NSURLResponse * _Nullable response, NSError * _Nullable error){

        [self completionBlockCodeInvoked];
        XCTAssertNotNil(error);
        XCTAssertNil(response);
        XCTAssertNil(data);
        BOOL isCancelled = [error.localizedDescription isEqualToString:@"cancelled"];
        XCTAssertTrue(isCancelled);
        [testExpectation fulfill];
    };

    NSURLSessionTask *nsSessionTask = [self.sessionManager dataTaskWithRequest:self.requestForMock completionHandler:requestCompletion];

    [msSessionTask setInnerTask:nsSessionTask];
    [msSessionTask cancel];
    [self waitForExpectations:@[testExpectation] timeout:5.0];
    [self checkCompletionBlockCodeInvoked];

}

- (void)testSetRequest{
    MSURLSessionTask *msSessionTask = [[MSURLSessionTask alloc] initWithRequest:self.requestForMock client:self.mockClient];

    NSMutableURLRequest *urlRequest = [msSessionTask request];
    [urlRequest setValue:@"Test" forHTTPHeaderField:@"TestHeader"];

    [msSessionTask setRequest:urlRequest];

    XCTAssertEqual(urlRequest, msSessionTask.request);
}

- (void)testExecute{
    MSDataCompletionHandler requestCompletion = ^(NSData *data, NSURLResponse * _Nullable response, NSError * _Nullable error){

        [self completionBlockCodeInvoked];
        XCTAssertNil(error);
        XCTAssertNotNil(response);
        XCTAssertNotNil(data);
    };

     MSURLSessionDataTask *dataTask = [[MSURLSessionDataTask alloc] initWithRequest:self.requestForMock client:self.mockClient completion:requestCompletion];
    id<MSGraphMiddleware> middleware = OCMPartialMock(dataTask.client.middleware);
    OCMStub([middleware execute:[OCMArg any] withCompletionHandler:[OCMArg any]]).andDo(^(NSInvocation *invocation){
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:MSGraphBaseURL] statusCode:MSExpectedResponseCodesOK HTTPVersion:@"foo" headerFields:nil];

        MSDataCompletionHandler completionHandler;
        [invocation getArgument:&completionHandler atIndex:3];
        completionHandler([NSData new],response,nil);
    });

    [dataTask execute];
    [self checkCompletionBlockCodeInvoked];

}
@end
