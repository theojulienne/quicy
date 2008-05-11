import std.stdio;

import quicy.all;
import ui.window;

int main( ) {
	Window w = new Window(  );
	
	w.init( "Quicy" );
	
	QuicyGame g = new QuicyGame;
	
	w.loop( &g.redraw, &g.event );
	
	return 0;
}
