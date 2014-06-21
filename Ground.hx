import box2D.dynamics.*;
import flash.display.*;
import flash.geom.*;
import box2D.common.math.*;
import box2D.collision.shapes.*;

class Ground extends GameObject {
	public var groundWidth:Int;

	override public function new(tileX:Float, tileY:Float, screenScale:Float, world:B2World, groundWidth:Int) {
		super(tileX, tileY, screenScale, world);
		this.groundWidth = groundWidth;

		var bodyDef = new B2BodyDef();
		bodyDef.fixedRotation = true;

		// "x2d sets the position of the center of an object, not the top left like normal"
		// Add a bit to the position so that a small nudge won't move immovable things to the next pixel.
		bodyDef.position.set(
			(0.05 + tileX)/screenScale, 
			(0.05 + tileY)/screenScale
		);

		var boxShape = new B2PolygonShape();

		// Takes half-width and half-height
		boxShape.setAsBox(
			(GameObject.spriteWidth * groundWidth * 0.5)/screenScale,
			(GameObject.spriteHeight * 0.5)/screenScale
		);

		var fixtureDef = new B2FixtureDef();
		fixtureDef.shape = boxShape;
		fixtureDef.friction = 1.0;
		fixtureDef.density = 1.0;
		fixtureDef.filter.categoryBits = 0x0001;
		fixtureDef.filter.maskBits = 0x0001 | 0x0002 | 0x0004;

		var body = world.createBody(bodyDef);
		body.setUserData(this);

		body.createFixture(fixtureDef);
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
