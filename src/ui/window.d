module ui.window;

import cairooo.all;

import derelict.sdl.sdl;
import derelict.sdl.image;
import derelict.opengl.gl;
import derelict.opengl.glu;
import derelict.util.exception;
import derelict.opengl.extension.arb.texture_rectangle;
import derelict.opengl.extension.ext.framebuffer_object;
import derelict.openal.al;

import icygl.all;

extern (C) void SDL_mac_prefix( );

static this()
{
    Cairo.load();

version(darwin)	SDL_mac_prefix( );
	DerelictSDL.load();
	DerelictSDLImage.load();
	DerelictGL.load();
	DerelictGLU.load();
	DerelictAL.load();
}

class Window
{
	SDL_Surface* screen;
	
	this( )
	{
		
	}
	
	int init( char[] title )
	{
		// Initialize SDL
		if(SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) < 0)
		{
			printf("Unable to init SDL: %s\n", SDL_GetError());
			SDL_Quit();
			return 1;
		}

		SDL_GL_SetAttribute( SDL_GL_DOUBLEBUFFER, 1 );

		// Create the screen surface (window)
		screen = SDL_SetVideoMode( 800, 600, 32, SDL_HWSURFACE | SDL_OPENGL );
		if(screen is null)
		{
			printf("Unable to set %sx%s video: %s\n", SDL_GetError());
			SDL_Quit();
			return 1;
		}
		
		SDL_WM_SetCaption( std.string.toStringz(title), std.string.toStringz(title) );

		try
		{
			DerelictGL.loadVersions(GLVersion.Version20);
		}
		catch(SharedLibProcLoadException slple)
		{
			// Here, you can check which is the highest version that actually loaded.
			/* Do Something Here */
		}

		DerelictGL.loadExtensions( );
		
		glClearColor( 0.0f, 0.0f, 0.0f, 0.0f );

		glViewport( 0, 0, screen.w, screen.h );

		glMatrixMode( GL_PROJECTION );
		glLoadIdentity();

		gluPerspective( 50.0, cast(float)screen.w/cast(float)screen.h, 0.1f, 100.0f );

		glMatrixMode( GL_MODELVIEW );
		glLoadIdentity();


		glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glEnable(GL_DEPTH_TEST);
		glClearDepth(1.0);				
		glDepthFunc(GL_LEQUAL);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glEnable(GL_BLEND);
		glAlphaFunc(GL_GREATER,0.01);
		glEnable(GL_ALPHA_TEST);				
		glEnable(GL_TEXTURE_2D);

		glHint(GL_POINT_SMOOTH, GL_NICEST);
		glHint(GL_LINE_SMOOTH, GL_NICEST);
		glHint(GL_POLYGON_SMOOTH, GL_NICEST);

		glEnable(GL_POINT_SMOOTH);
		glEnable(GL_LINE_SMOOTH);
		glEnable(GL_POLYGON_SMOOTH);
		
		return 0;
	}
	
	void setOrthographicProjection() {

		// switch to projection mode
		glMatrixMode(GL_PROJECTION);
		// save previous matrix which contains the 
		//settings for the perspective projection
		glPushMatrix();
		// reset matrix
		glLoadIdentity();
		// set a 2D orthographic projection
		gluOrtho2D(0, screen.w, 0, screen.h);
		// invert the y axis, down is positive
		glScalef(1, -1, 1);
		// mover the origin from the bottom left corner
		// to the upper left corner
		glTranslatef(0, -screen.h, 0);
		glMatrixMode(GL_MODELVIEW);
		glPushMatrix( );
	}
	
	void resetPerspectiveProjection() {
		glPopMatrix( );
		glMatrixMode(GL_PROJECTION);
		glPopMatrix();
		glMatrixMode(GL_MODELVIEW);
	}
	
	void ortho( bool enable) {
		if ( enable )
			setOrthographicProjection( );
		else
			resetPerspectiveProjection( );
	}
	
	bool running;
	
	void loop( void delegate(Window w) redraw, void delegate(SDL_Event e) handle_event ) {
		running = true;
		
		// main loop
		while(running)
		{
			SDL_Event event;
			while(SDL_PollEvent(&event))
			{
				switch(event.type)
				{
					// exit if SDLK or the window close button are pressed
					case SDL_KEYUP:
						if(event.key.keysym.sym == SDLK_ESCAPE)
							running = false;
						else
							handle_event( event );
						break;
					case SDL_QUIT:
						running = false;
						break;
					default:
						break;
				}
			}
			
			SDL_Delay(0);
			
			glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
			
			glDisable( GL_TEXTURE_2D );
			glEnable( GL_TEXTURE_RECTANGLE_ARB );
			
			redraw( this );
			
			handleGLError( "preflush" );
			glFlush( );
			SDL_GL_SwapBuffers();
		}
	}
}