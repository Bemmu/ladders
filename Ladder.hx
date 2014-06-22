import flash.geom.*;
import flash.display.*;
import box2D.collision.shapes.*;
import box2D.dynamics.*;

class Ladder extends GameObject {
	override public function new(tileX:Float, tileY:Float, screenScale:Float, world:B2World, height:Float) {
		super(tileX, tileY, screenScale, world);
		isLadder = true;

		var bodyDef = new B2BodyDef();
		bodyDef.fixedRotation = false;
		bodyDef.position.set(
			tileX/screenScale, 
			(tileY - height*GameObject.spriteHeight*0.5)/screenScale
		);
		var fixtureDef = new B2FixtureDef();

		var boxShape = new B2PolygonShape();
		boxShape.setAsBox(
			(GameObject.spriteWidth * 0.5)/screenScale, 
			(GameObject.spriteHeight * 0.5 * height)/screenScale
		);

		fixtureDef.filter.categoryBits = 0x0004;
		fixtureDef.filter.maskBits = 0x0001 | 0x0004;
		fixtureDef.shape = boxShape;
		fixtureDef.friction = 0.5;
		fixtureDef.density = 1.0;

		bodyDef.type = B2Body.b2_dynamicBody;
		bodyDef.allowSleep = false;

		body = world.createBody(bodyDef);
		body.setUserData(this);

		body.createFixture(fixtureDef);
	}

	override public function draw(buffer:BitmapData, sheet:BitmapData, bodyX:Int, bodyY:Int) {
//		buffer.fillRect(new Rectangle(bodyX, bodyY, 10, 10), 0xff00ffff);

		// To draw, need to find the corners.
		// To find the corners, need ... physics body info and screenscale.

	}
}
