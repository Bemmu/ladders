import flash.geom.*;
import flash.display.*;
import box2D.collision.shapes.*;
import box2D.dynamics.*;
import box2D.common.math.*;

class Ladder extends GameObject {
	var boxSize:B2Vec2;

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
		boxSize = new B2Vec2((GameObject.spriteWidth * 0.5)/screenScale, (GameObject.spriteHeight * 0.5 * height)/screenScale);

		boxShape.setAsBox(
			boxSize.x, boxSize.y
		);

		fixtureDef.filter.categoryBits = 0x0004;
		fixtureDef.filter.maskBits = 0x0001 | 0x0004;
		fixtureDef.shape = boxShape;
		fixtureDef.friction = 1.0;
		fixtureDef.density = 1.0;

		bodyDef.type = B2Body.b2_dynamicBody;
		bodyDef.allowSleep = false;

		body = world.createBody(bodyDef);
		body.setUserData(this);

		body.createFixture(fixtureDef);
	}

	override public function draw(buffer:BitmapData, sheet:BitmapData, bodyX:Int, bodyY:Int) {

		// Find corners of the ladder in world coordinates.
		var shape = new Shape();
		shape.graphics.lineStyle(1, 0xFFD700, 1, false, LineScaleMode.VERTICAL,
                               CapsStyle.NONE, JointStyle.MITER, 10);
		shape.graphics.moveTo(
			body.getWorldPoint(new B2Vec2(-boxSize.x, -boxSize.y)).x * screenScale, 
			body.getWorldPoint(new B2Vec2(-boxSize.x, -boxSize.y)).y * screenScale
		);
		shape.graphics.lineTo(
			body.getWorldPoint(new B2Vec2(boxSize.x, -boxSize.y)).x * screenScale, 
			body.getWorldPoint(new B2Vec2(boxSize.x, -boxSize.y)).y * screenScale
		); 
		shape.graphics.lineTo(
			body.getWorldPoint(new B2Vec2(boxSize.x, boxSize.y)).x * screenScale, 
			body.getWorldPoint(new B2Vec2(boxSize.x, boxSize.y)).y * screenScale
		); 
		shape.graphics.lineTo(
			body.getWorldPoint(new B2Vec2(-boxSize.x, boxSize.y)).x * screenScale, 
			body.getWorldPoint(new B2Vec2(-boxSize.x, boxSize.y)).y * screenScale
		); 
		shape.graphics.lineTo(
			body.getWorldPoint(new B2Vec2(-boxSize.x, -boxSize.y)).x * screenScale, 
			body.getWorldPoint(new B2Vec2(-boxSize.x, -boxSize.y)).y * screenScale
		); 
		buffer.draw(shape);
	}
}
