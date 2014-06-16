import flash.geom.*;
import flash.display.*;
import box2D.dynamics.*;

class Ladder extends GameObject {
	override public function new(body:B2Body, world:B2World, screenScale:Float) {
		super(body, world, screenScale);
		isLadder = true;
	}

	override public function draw(buffer:BitmapData, sheet:BitmapData, bodyX:Int, bodyY:Int) {
		buffer.fillRect(new Rectangle(bodyX, bodyY, 10, 10), 0xff00ffff);

		// To draw, need to find the corners.
		// To find the corners, need ... physics body info and screenscale.

	}
}
