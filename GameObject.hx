import flash.geom.*;
import flash.display.*;
import box2D.dynamics.*;

// To add behavior and drawing to Box2D bodies
class GameObject {
	public static var spriteWidth = 20; // in pixels
	public static var spriteHeight = 22;
	public var flipped = false;
	public var frame = 0.0;
	public var body:B2Body = null;
	var world:B2World = null;
	var isLadder = false;
	var screenScale:Float;

	public function tick() {
	}

	public function new(tileX:Float, tileY:Float, screenScale:Float, world:B2World) {
		this.world = world;
		this.screenScale = screenScale;
	}

	public function copyPixelsFromSpriteSheet(buffer:BitmapData, sheet:BitmapData, dest:Point) {
		var sourceY = 0;
		if (flipped) {
			sourceY = spriteHeight; // Flipped versions of sprites are on second row of sprite sheet
		}

		var source = new Rectangle(spriteWidth * Math.floor(frame), sourceY, spriteWidth, spriteHeight);

		buffer.copyPixels(
			sheet,
			source,
			dest,
			null, null, true // alpha
		);
	}

	// Is the center point over a ladder? (regardless if holding on to it)
	function overLadder():B2Body {
		var ladder = null;
		world.queryPoint(function (fixture:box2D.dynamics.B2Fixture):Bool {
			var gameObject:GameObject = fixture.getBody().getUserData();
			if (gameObject != null) {
				if (gameObject.isLadder) {
					ladder = fixture.getBody();
				}
			}
			return true;
		}, body.getPosition());
		return ladder;
	}

	public function draw(buffer:BitmapData, sheet:BitmapData, bodyX:Int, bodyY:Int) {
	}

/*	public function someBodyAtPoint(px, py):Bool {
	    // Make a small box.
	    var px2 = px;
	    var py2 = py;
	    var pointVec:B2Vec2 = new B2Vec2();
	    pointVec.set(px2, py2);
	    var aabb = new B2AABB();
	    aabb.lowerBound.set(px2 - 0.001, py2 - 0.001);
	    aabb.upperBound.set(px2 + 0.001, py2 + 0.001);
	    
	    // Query the world for overlapping shapes.
	    var k_maxCount:Int = 10;
	    var shapes = [];

	    overlaps = false;
	    world.queryAABB(callback, aabb);
	    return overlaps;
	}
*/
}
