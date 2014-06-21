import box2D.dynamics.*;
import flash.display.*;
import flash.events.*;
import flash.geom.*;
import flash.utils.*;
import flash.ui.*;
import box2D.common.math.*;

class Player extends StickMan {
	var keys:Map<Int, Bool> = new Map();
	
	override public function new(body:B2Body, world:B2World, screenScale:Float, keys:Map<Int, Bool>) {
		super(body, world, screenScale);
		this.keys = keys;
	}

	override public function tick() {
		var vel = body.getLinearVelocity();

		var max_velocity = 6.0;
		if (vel.x > max_velocity) vel.x = max_velocity;
		if (vel.x < -max_velocity) vel.x = -max_velocity;
		body.setLinearVelocity(new B2Vec2(vel.x, vel.y));

		if (keys[Keyboard.RIGHT] || keys[Keyboard.D]) {

/*			note scaling not fixed here var ax = body.getWorldCenter().x + GameObject.spriteWidth/screenScale * 0.55;
			var ay = body.getWorldCenter().y - GameObject.spriteHeight/screenScale * 0.40;
			var bx = body.getWorldCenter().x + GameObject.spriteWidth/screenScale * 0.55;
			var by = body.getWorldCenter().y + GameObject.spriteHeight/screenScale * 0.40;*/
//			var groundOnRight:Bool = someBodyAtPoint(ax, ay) || someBodyAtPoint(bx, by);

//			if (!groundOnRight) {
				body.applyImpulse(new B2Vec2(
					0.5,
					0.0
				), body.getWorldCenter());
//			}
		}

		if (keys[Keyboard.LEFT] || keys[Keyboard.A]) {
/*			var groundOnLeft = someBodyAtPoint(player.getWorldCenter().x - tileWidth * 0.55, player.getWorldCenter().y - tileHeight * 0.40)
	 		|| someBodyAtPoint(player.getWorldCenter().x - tileWidth * 0.55, player.getWorldCenter().y + tileHeight * 0.40);

			if (!groundOnLeft) {*/
				body.applyImpulse(new B2Vec2(
					-0.5,
					0.0
				), body.getWorldCenter());
//			}
		}

		if (keys[Keyboard.UP]||keys[Keyboard.W]) {
			if (isHoldingOnToLadder()) {
				moveAlongLadder(true);
			} else {
				tryGrabbingLadder();
			}
		}

		if (keys[Keyboard.DOWN]||keys[Keyboard.S]) {
			if (isHoldingOnToLadder()) {
				moveAlongLadder(false);
			}
		}

		if (keys[Keyboard.SPACE]||keys[Keyboard.Z]||keys[Keyboard.X]) {
			letGoOfLadder();
//			jump();
		} else {
			canStillJumpTicks = 0;
		}
	}
}
