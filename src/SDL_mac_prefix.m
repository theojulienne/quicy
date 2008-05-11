#include <Cocoa/Cocoa.h>

void CPSEnableForegroundOperation( ProcessSerialNumber* psn );

NSAutoreleasePool *arpool;
NSObject *app;

/* called at initialisation */
void SDL_mac_prefix( )
{
	NSApplicationLoad( );
	
	arpool = [[NSAutoreleasePool alloc] init];
	
	[NSApplication sharedApplication];
	
	[NSApp setMainMenu:[[NSMenu alloc] init]];
	
	app = [[NSObject alloc] init];
	[NSApp setDelegate: app];
	
	
	ProcessSerialNumber myProc, frProc;
	Boolean sameProc;

	if ( GetFrontProcess( &frProc ) == noErr && GetCurrentProcess( &myProc ) == noErr )
	{
		if ( SameProcess( &frProc, &myProc, &sameProc ) == noErr && !sameProc )
		{
			CPSEnableForegroundOperation( &myProc );
		}
		
		SetFrontProcess( &myProc );
	}
}