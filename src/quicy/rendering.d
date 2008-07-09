module quicy.rendering;

import cairooo.all;
import icygl.all;
import derelict.opengl.gl;

struct Color
{
	double r, g, b, a;
	
	static Color create( float r, float g, float b )
	{
		Color c;
		c.r = r;
		c.g = g;
		c.b = b;
		c.a = 1;
		return c;
	}
}

class Rendering
{
	this( )
	{
		
	}
	
	struct BlockImage
	{
		ImageBufferSurface surface;
		Context context;
		Texture texture;
		
		void redraw( Color c, float mask_r, int type )
		{
			auto acr = context;
			
			acr.save( );

			acr.scale( surface.width, surface.height );

			acr.rectangle(0, 0, 1, 1);
			if ( type == 1 ) {
		    	acr.setSourceRGBA(0, 0, 0, 0.25);
			} else {
				acr.setSourceRGBA(1.0, 1.0, 1.0, 0.5);
			}
		    //acr.operator = Operator.Clear;
		    acr.fill();

			acr.restore( );

			void drawRoundedRect( Context c, float x, float y, float w, float h, float r )
			{
				c.save( );
				c.moveTo( x+r,y );
				c.lineTo( x+w-r,y );
				c.curveTo( x+w,y,x+w,y,x+w,y+r );
				c.lineTo( x+w,y+h-r );
			    c.curveTo( x+w,y+h,x+w,y+h,x+w-r,y+h );
			    c.lineTo( x+r,y+h );
			    c.curveTo( x,y+h,x,y+h,x,y+h-r );
			    c.lineTo( x,y+r );
			    c.curveTo( x,y,x,y,x+r,y );
				c.closePath( );

				c.restore( );
			}

			acr.lineWidth = 5;
			
			if ( type == 1 ) {
		    	acr.setSourceRGBA(c.r, c.g, c.b, 0.25);
			} else {
				acr.setSourceRGBA(c.r, c.g, c.b, 0.8);
			}
		 	acr.operator = Operator.Over;
		    //acr.arc(0.5, 0.5, 0.4, 0, 2*PI);
			
			acr.rectangle(0, 0, surface.width, surface.height);
			
			acr.fill();
			
			if ( type == 1 ) {
				acr.setSourceRGBA(c.r, c.g, c.b, 0.5);
				drawRoundedRect( acr, 5, 5, surface.width-10, surface.height-10, surface.width / 10.0 * mask_r );
				acr.fill();
			} else {
				acr.setSourceRGBA(c.r, c.g, c.b, 0.5);
				drawRoundedRect( acr, 5, 5, surface.width-10, surface.height-10, surface.width / 10.0 * mask_r );
				acr.fill();
			}

			texture.updateData( 0, GL_RGBA, GL_BGRA, GL_UNSIGNED_BYTE, surface.width, surface.height, surface.data.ptr, 0 );
		}
	}
	
	static BlockImage[Color] blockImages;
	
	static Texture createBlockImage( Color c, int width=16, int height=16, int type=0 )
	{
		BlockImage im;
		
		//if ( c in blockImages )
		//	return blockImages[c].texture;
		
		im.surface = new ImageBufferSurface(Format.ARGB32, width, height);
	    im.context = new Context(im.surface);
		im.texture = new ImageTexture( );
		
		im.redraw( c, 5, type );
		
		blockImages[c] = im;
		
		return im.texture;
	}
}