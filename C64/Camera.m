#import "Camera.h"

@implementation Camera

#pragma mark -
#pragma mark Initialization and teardown

-(BOOL)canFlip {
	return canFlip;
}

-(void)start {
    if (![captureSession isRunning]) [captureSession startRunning];
}

-(void)stop {
    if ([captureSession isRunning]) [captureSession stopRunning];
}

-(BOOL)setHighQuality:(BOOL)highQ {
    if(highQ == highQuality) return FALSE;

    [self stop];
    [captureSession setSessionPreset:(highQ ? AVCaptureSessionPresetMedium : AVCaptureSessionPreset352x288)];	
    [self start];
    highQuality = highQ;
    
    return TRUE;
}

-(void)setup {
	// Grab the front or back-facing camera depending on frontFacing boolean that starts out as FALSE
	AVCaptureDevice *backFacingCamera = nil, *frontFacingCamera = nil;
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	for (AVCaptureDevice *device in devices) {
		if ([device position] == AVCaptureDevicePositionBack) {
			backFacingCamera = device;
		} 
		if ([device position] == AVCaptureDevicePositionFront) {
			frontFacingCamera = device;
		} 		
	}
	canFlip = frontFacingCamera != nil && backFacingCamera != nil;
	
	// Create the capture session
	captureSession = [[AVCaptureSession alloc] init];
	
	// Add the video input	
	NSError *error = nil;
	AVCaptureDevice* activeCamera = frontFacing ? frontFacingCamera : backFacingCamera;
	videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:activeCamera error:&error];
	if ([captureSession canAddInput:videoInput]) 
	{
		[captureSession addInput:videoInput];
	}
	
	[self videoPreviewLayer];
	// Add the video frame output	
	videoOutput = [[AVCaptureVideoDataOutput alloc] init];
	[videoOutput setAlwaysDiscardsLateVideoFrames:YES];
	// Use RGB frames instead of YUV to ease color processing
	[videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] 
															  forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
	
	//	dispatch_queue_t videoQueue = dispatch_queue_create("com.sunsetlakesoftware.colortracking.videoqueue", NULL);
	[videoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
	
	if ([captureSession canAddOutput:videoOutput]) {
		[captureSession addOutput:videoOutput];
	} else {
		//NSLog(@"Couldn't add video output");
	}
	
    [captureSession setSessionPreset:(highQuality ? AVCaptureSessionPresetMedium : AVCaptureSessionPreset352x288)];
}

- (id)init {
	if (!(self = [super init])) return nil;
	[self setup];	
	return self;
}

-(void)shutdown {
	[captureSession stopRunning];
	
	captureSession = nil;
	videoPreviewLayer = nil;
    videoOutput = nil;
	videoInput = nil;
}

-(void)flipCamera {
	[self stop];
	frontFacing = !frontFacing;
	[self shutdown];
	[self setup];
	[self start];
}

- (void)dealloc {
	[self shutdown];
}

#pragma mark -
#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
	CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	[self.delegate processNewCameraFrame:pixelBuffer];
}

#pragma mark -
#pragma mark Accessors

@synthesize delegate;
@synthesize videoPreviewLayer;

- (AVCaptureVideoPreviewLayer *)videoPreviewLayer;
{
	if (videoPreviewLayer == nil)
	{
		videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
        
        if ([videoPreviewLayer isOrientationSupported]) 
		{
            [videoPreviewLayer setOrientation:AVCaptureVideoOrientationPortrait];
        }
        
        [videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
	}
	
	return videoPreviewLayer;
}

@end
