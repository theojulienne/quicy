module quicy.board;

import std.stdio;
import std.date;
import std.math;
import std.random;

import derelict.sdl.sdl;
import derelict.opengl.gl;

import ui.window;
import icygl.all;

import quicy.rendering;

int min( int a, int b ) {
	return a > b ? b : a;
}

int max( int a, int b ) {
	return a < b ? b : a;
}

class Block {
	int _x, _y;
	int color;
	
	Shape shape;
	
	this( int x, int y, Shape s=null )
	{
		this._x = x;
		this._y = y;
		this.shape = s;
	}
	
	int x( ) {
		if ( shape !is null )
			return shape.x + _x;
		
		return _x;
	}
	
	int y( ) {
		if ( shape !is null )
			return shape.y + _y;
		
		return _y;
	}
	
	void deShape( ) {
		color = shape.type;
		shape = null;
	}
}

class Shape {
	enum Type {
		I=0,
		O=1,
		T=2,
		S=3,
		Z=4,
		J=5,
		L=6
	}
	
	
	Block[4] blocks;
	int color;
	
	int x, y;
	Type type;
	
	this( Type t ) {
		this.type = t;
		
		switch ( type ) {
			case Type.I: {
				blocks[0] = new Block( -2,  0, this );
				blocks[1] = new Block( -1,  0, this );
				blocks[2] = new Block(  0,  0, this );
				blocks[3] = new Block(  1,  0, this );
				break;
			}
			
			case Type.O: {
				blocks[0] = new Block(  0,  0, this );
				blocks[1] = new Block(  1,  0, this );
				blocks[2] = new Block(  1,  1, this );
				blocks[3] = new Block(  0, 1, this );
				break;
			}
			
			case Type.T: {
				blocks[0] = new Block( -1,  0, this );
				blocks[1] = new Block(  0,  0, this );
				blocks[2] = new Block(  1,  0, this );
				blocks[3] = new Block(  0, -1, this );
				break;
			}
			
			case Type.S: {
				blocks[0] = new Block(  1, -1, this );
				blocks[1] = new Block(  0, -1, this );
				blocks[2] = new Block(  0,  0, this );
				blocks[3] = new Block( -1,  0, this );
				break;
			}
			
			case Type.Z: {
				blocks[0] = new Block( -1, -1, this );
				blocks[1] = new Block(  0, -1, this );
				blocks[2] = new Block(  0,  0, this );
				blocks[3] = new Block(  1,  0, this );
				break;
			}
			
			case Type.L: {
				blocks[0] = new Block( -1,  0, this );
				blocks[1] = new Block(  0,  0, this );
				blocks[2] = new Block(  1,  0, this );
				blocks[3] = new Block(  1, -1, this );
				break;
			}
			
			case Type.J: {
				blocks[3] = new Block( -1, -1, this );
				blocks[0] = new Block( -1,  0, this );
				blocks[1] = new Block(  0,  0, this );
				blocks[2] = new Block(  1,  0, this );
				break;
			}
			
			default: {
				
				break;
			}
		}
	}
	
	void rotate( bool clockwise=false ) {
		foreach ( block; blocks ) {
			int tmpx = block._x;
			int tmpy = block._y;
			
			if ( clockwise ) {
				block._x = -tmpy;
				block._y = tmpx;
			} else {
				block._x = tmpy;
				block._y = -tmpx;
			}
		}
	}
	
	void getBlockExtents( out int small_x, out int small_y, out int large_x, out int large_y ) {
		small_x = small_y = large_x = large_y = 0;
		
		foreach ( block; blocks ) {
			small_x = min( small_x, block._x );
			small_y = min( small_y, block._y );
			
			large_x = max( large_x, block._x );
			large_y = max( large_y, block._y );
		}
	}
}

class Board {
	Block[10][20] blocks;
	
	Shape currentPiece;
	
	int score;
	int lines;
	int level;
	
	static const int levelUpLines = 10;
	
	static const int pointsPerLineSkipped = 3;
	static const int pointsPerPlacement = 4;
	
	static const int[] scoreLineMultiplier = [ 40, 100, 300, 1200 ];
	
	this( ) {
		int x, y;
		
		for ( y = 0; y < blocks.length; y++ ) {
			for ( x = 0; x < blocks[y].length; x++ ) {
				blocks[y][x] = null;
			}
		}
		
		randomCurrentPiece( );
		
		score = 0;
		level = 0;
		lines = 0;
	}
	
	bool shapeCollides( Shape s ) {
		int sx, sy, lx, ly;
		
		currentPiece.getBlockExtents( sx, sy, lx, ly );
		
		sx += s.x;
		sy += s.y;
		lx += s.x;
		ly += s.y;
		
		if ( sx < 0 || lx >= blocks[0].length ) {
			return true; // hits side walls
		}
		
		if ( ly >= blocks.length ) {
			return true; // bottom of pit
		}
		
		// now, does it collide with a piece?
		foreach ( block; currentPiece.blocks ) {
			if ( block.y < 0 ) continue;
			
			if ( blocks[block.y][block.x] !is null ) {
				return true;
			}
		}
		
		return false;
	}
	
	void rotateCurrentPiece( bool clockwise ) {
		currentPiece.rotate( clockwise );
		
		if ( shapeCollides( currentPiece ) ) {
			// undo
			currentPiece.rotate( !clockwise );
		}
	}
	
	void moveCurrentPiece( bool right ) {
		int adder = right ? 1 : -1;
		
		currentPiece.x += adder;
		
		if ( shapeCollides( currentPiece ) ) {
			// undo
			currentPiece.x -= adder;
		}
	}
	
	bool lowerCurrentPiece( bool hardDrop=false, int hardDropCounter=0 ) {
		currentPiece.y += 1;
		
		if ( shapeCollides( currentPiece ) ) {
			// undo
			currentPiece.y -= 1;
			
			// start counter etc here
			// for now, just play the piece
			commitCurrentPiece( hardDrop, hardDropCounter );
			randomCurrentPiece( );
			
			return false;
		}
		
		return true;
	}
	
	void commitCurrentPiece( bool wasHardDrop, int hardDropCounter ) {
		foreach ( block; currentPiece.blocks ) {
			if ( block.y < 0 ) {
				throw new Exception( "You lose!" );
			}
			blocks[block.y][block.x] = block;
			block.deShape( );
		}
		
		int linesRemoved = cleanCompleteLines( );
		//writefln( "you completed %s rows!", linesRemoved );
		lines += linesRemoved;
		
		int scoreAddition = 0;
		
		if ( wasHardDrop ) {
			scoreAddition += hardDropCounter * pointsPerLineSkipped;
		} else {
			scoreAddition += pointsPerPlacement;
		}
		
		if ( linesRemoved > 0 )
			scoreAddition += scoreLineMultiplier[linesRemoved-1] * (level+1);
		
		level = lines / 10;

		addScore( scoreAddition );
	}
	
	void addScore( int points ) {
		score += points;
		writefln( "Lines: %02d        Level: %02d        Score: %10d", lines, level, score );
	}
	
	void randomCurrentPiece( ) {
		currentPiece = new Shape( cast(Shape.Type) (rand() % (Shape.Type.max+1)) );
		currentPiece.x = 5;
		currentPiece.y = 0;
	}
	
	int cleanCompleteLines( ) {
		int linesFound = 0;
		
		for ( int y = blocks.length-1; y >= 0; y-- ) {
			bool complete = true;
			
			foreach ( x, block; blocks[y] ) {
				if ( block is null )
					complete = false;
			}
			
			if ( complete ) {
				moveLinesDownAbove( y );
				linesFound++;
				y++; // do this line again
			}
		}
		
		return linesFound;
	}
	
	void moveLinesDownAbove( int start ) {
		for ( int y = start; y > 0; y-- ) {
			moveLine( y-1, y );
		}
	}
	
	void moveLine( int from, int to ) {
		for ( int x = 0; x < blocks[0].length; x++ ) {
			blocks[to][x] = blocks[from][x];
		}
	}
}

class QuicyGame {
	Texture background_block;
	Board board;
	d_time last_render_time;
	double time_counter = 0;
	
	Texture[7] colors;
	
	static const int blockSize = 24;
	static const int blockSpacing = blockSize + (blockSize / 8);
	
	this( ) {
		last_render_time = getUTCtime;
		time_counter = 0;
		
		background_block = Rendering.createBlockImage( Color.create( 0.05, 0.05, 0.05 ), blockSize, blockSize );
		board = new Board;
		
		rand_seed( cast(int)last_render_time, 0 );
		
		//board.currentPiece.x = 5;
		
		colors[0] = Rendering.createBlockImage( Color.create( 0, 1, 1 ), blockSize, blockSize );
		colors[1] = Rendering.createBlockImage( Color.create( 0, 0, 1 ), blockSize, blockSize );
		colors[2] = Rendering.createBlockImage( Color.create( 1, 0.5, 0 ), blockSize, blockSize );
		colors[3] = Rendering.createBlockImage( Color.create( 1, 1, 0 ), blockSize, blockSize );
		colors[4] = Rendering.createBlockImage( Color.create( 0, 1, 0 ), blockSize, blockSize );
		colors[5] = Rendering.createBlockImage( Color.create( 0.5, 0, 1 ), blockSize, blockSize );
		colors[6] = Rendering.createBlockImage( Color.create( 1, 0, 0 ), blockSize, blockSize );
	}
	
	bool paused = false;
	
	void redraw( Window w ) {
		d_time now = getUTCtime( );
		double ofs = now - last_render_time;
		ofs /= TicksPerSecond;
		last_render_time = now;
		
		time_counter += ofs;
		
		double piecePause = 1;
		
		piecePause = 1 - (board.level * 0.01);
		
		if ( piecePause < 0.1 )
			piecePause = 0.1;
		
		if ( !paused && time_counter > piecePause ) {
			time_counter -= piecePause;
			
			board.lowerCurrentPiece( );
		}
		
		w.ortho = true;
		
		glLoadIdentity( );
		glTranslatef( 50, 50, 0 );
		glColor4f( 1, 1, 1, 1 );
		
		void drawBlock( Texture t, int x, int y ) {
			t.activate( GL_TEXTURE0, 0 );
			
			glPushMatrix( );
			glTranslatef( x*blockSpacing, y*blockSpacing, 0 );
			drawTexturedQuad( blockSize, blockSize, t );
			glPopMatrix( );
		}
		
		// draw background
		
		foreach ( y, row; board.blocks ) {
			foreach ( x, block; row ) {
				if ( block is null )
					drawBlock( background_block, x, y );
				else {
					drawBlock( colors[block.color], x, y );
				}
			}
		}
		
		Shape shape = board.currentPiece;
		foreach ( block; shape.blocks ) {
			drawBlock( colors[shape.type], block.x, block.y );
		}
		
		w.ortho = false;
	}
	
	void event( SDL_Event e ) {
		if ( e.type != SDL_KEYUP )
			return;
		
		switch ( e.key.keysym.sym ) {
			case SDLK_UP:
				board.rotateCurrentPiece( false	 );
				
				break;
			case SDLK_LEFT:
				board.moveCurrentPiece( false );
				
				break;
			case SDLK_RIGHT:
				board.moveCurrentPiece( true );
				
				break;
			case SDLK_DOWN:
				int hardDropCounter = 1;
				while ( board.lowerCurrentPiece( true, hardDropCounter ) ) {
					hardDropCounter++;
				}
				
				break;
			case 'p':
				paused = !paused;
				last_render_time = getUTCtime;
				time_counter = 0;
				break;
			default:
				writefln( "I don't understand that key." );
				break;
		}
	}
}