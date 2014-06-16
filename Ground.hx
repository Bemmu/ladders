import box2D.dynamics.*;
import flash.display.*;
import flash.geom.*;
import box2D.common.math.*;

class Ground extends GameObject {
	public var groundWidth:Int;

	override public function new(body:B2Body, world:B2World, screenScale:Float, groundWidth:Int) {
		super(body, world, screenScale);
		this.groundWidth = groundWidth;
	}

	override public function draw(buffer:BitmapData, sheet:BitmapData, bodyX:Int, bodyY:Int) {
		for (i in 0...groundWidth) {
			copyPixelsFromSpriteSheet(buffer, sheet, new Point(
				bodyX - 10 - (groundWidth-1) * GameObject.spriteWidth * 0.5 + i * GameObject.spriteWidth, 
				bodyY - 11
			));
		}
	}

}
