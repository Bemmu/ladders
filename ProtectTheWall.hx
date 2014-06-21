import flash.display.*;
import box2D.dynamics.*;
import box2D.dynamics.joints.*;
import box2D.dynamics.contacts.*;
import box2D.common.math.*;
import box2D.collision.shapes.*;
import flash.events.*;

class ContactListener extends B2ContactListener {
    public function new() {
    	super();
    }

    override public function beginContact(contact:B2Contact) {
    }
}

class ProtectTheWall {
	var buffer:BitmapData = null;
	var sheet:BitmapData = null;
	var keys:Map<Int, Bool> = new Map();
	public var screenScale = 30; // 30 pixels = 1 meter

	// tileWidth and height are in pixels

	var world:B2World;
	var debugSprite:Sprite;
	var player:B2Body = null;
	var jumpImpulse = 350;
	var ladderGrabDistance = 4;

	function tick() {
		world.step(1.0/60.0, 10, 10);

		var body = world.getBodyList();
		var gameObject:GameObject;

		while (body != null) {
			gameObject = body.getUserData();
			if (gameObject != null) {
				gameObject.tick();
			}
			body = body.getNext();
		}
	}

	var i = 0;

	function drawBodies() {
		i++;
		var body = world.getBodyList();
		while (body != null) {
			var gameObject:GameObject = body.getUserData();

			// There is initially one default body added by Box2D with no attached UserData. Ignore it.
			if (gameObject == null) {
				body = body.getNext();
				continue;
			}

			gameObject.draw(buffer, sheet, 
				Math.floor(body.getPosition().x * screenScale), 
				Math.floor(body.getPosition().y * screenScale)
			);
			gameObject.tick();

			body = body.getNext();
		}
	}

	function refresh() {
		buffer.fillRect(buffer.rect, 0xff0000ff);
		drawBodies();
		world.drawDebugData();
		buffer.draw(debugSprite);
		tick();
	}

	function createGroundAt(tileX:Float, tileY:Float, groundWidth:Int) {
		var ground = new Ground(tileX, tileY, screenScale, world, groundWidth);
		return ground.body;
	}

	function createPlayerAt(tileX:Float, tileY:Float) {
		var player = new Player(tileX, tileY, screenScale, world, keys); 
		return player.body;
	}

	function createLadderAt(tileX:Float, tileY:Float, height:Float) {
		var ladder = new Ladder(tileX, tileY, screenScale, world, height);
		return ladder.body;
	}

	function makeLevel() {
		var ladderAlreadyCreated:Map<String, Bool> = new Map();
		var level = Levels.levels[1];

		var y = 15; // x and y refer to the level string here
		while (y > 0) {
			y--;

			var prevCh = null;
			var groundWidth = 0; // for making larger physics blocks for ground (i.e. 10x1 instead of ten 1x1)

			for (x in 0...28) {

				var ch = level.charAt(y * 29 + x); // level is represented by characters, look at Levels.hx if you don't get it
				var nextCh = level.charAt(y * 29 + x + 1); // lookahead
				var physX:Float = (x + 0.5) * GameObject.spriteWidth;
				var physY:Float = (y + 0.5) * GameObject.spriteHeight;

				// If there are several ground tiles next to each other then create one bigger continuous
				// block. Otherwise sliding on it won't work properly (some Box2D quirk?). 
				if (ch == 'x') {
					groundWidth += 1;
				}
				if (ch != nextCh) {
					if (ch == 'x') {
						var st:Float = physX - (groundWidth - 1) * GameObject.spriteWidth * 0.5;
						createGroundAt(st, physY, groundWidth);
					}
					groundWidth = 0;
				}

				if (ch == '@') {
					player = createPlayerAt(physX, physY);
				}

				// Digits signify ladder pieces
				var isLadder = ch == '1'||ch == '2'||ch == '3'||ch == '4'||ch == '5'||ch == '6'||ch == '7'||ch == '8'||ch == '9';
				if (isLadder) {
					// Stop if this ladder has already been created
					if (!ladderAlreadyCreated[ch]) {

						// Peek ahead how high this ladder should be
						var yLookAhead = y;
						while (yLookAhead > 0) {
							yLookAhead--;
							if (level.charAt(yLookAhead * 29 + x) != ch) {
								break;
							}
						}
						var ladderHeight = y - yLookAhead;

						createLadderAt(physX, physY, ladderHeight);
					}
					ladderAlreadyCreated[ch] = true;
				}
			}
		}
	}

	function initKeyboard() {
		flash.Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, function (e) {
			keys[e.keyCode] = true;
		});
		flash.Lib.current.stage.addEventListener(KeyboardEvent.KEY_UP, function (e) {
			keys[e.keyCode] = false;
		});
	}

	function OnEnter(e:flash.events.Event) {
		refresh();
	}

	function debugSetup() {
		debugSprite = new Sprite();
		var debugDraw = new B2DebugDraw();
		debugDraw.setSprite(debugSprite);
		debugDraw.setDrawScale(screenScale);
		debugDraw.setFillAlpha(0.3);
		debugDraw.setLineThickness(2.0);
		debugDraw.setFlags(B2DebugDraw.e_shapeBit | B2DebugDraw.e_jointBit);
		world.setDebugDraw(debugDraw);
	}

	var contactListener:B2ContactListener;

	public function new(sheet:flash.display.BitmapData) {
		this.sheet = sheet;

		world = new B2World(new B2Vec2(0.0, 30.0), true);

		contactListener = new ContactListener();
		world.setContactListener(contactListener);
		makeLevel();
		//player = createPlayerAt(100.0, 0.0);
		initKeyboard();

		buffer = new BitmapData(flash.Lib.current.stage.stageWidth, flash.Lib.current.stage.stageHeight);
		var mc:flash.display.MovieClip = flash.Lib.current;
		mc.addChild(new Bitmap(buffer));

		flash.Lib.current.stage.addEventListener(Event.ENTER_FRAME, OnEnter);
		debugSetup();
	}

	var overlaps:Bool;
	function callback(fixture:B2Fixture) {
		var userData:Map<String,Dynamic> = fixture.getBody().getUserData();
		var type:String = userData['type'];
		if (type == 'player') {
			return true; // continue to next fixture
		}
    	overlaps = true;    	
    	return false; // don't continue to next fixture
	}

	function createTestJoint(bodyB:B2Body):B2Joint {
		if (player == null) {
			trace("Player was NULL when trying to create ladder joint.");
			return null;
		}
		var jointDef = new B2DistanceJointDef();
		jointDef.bodyA = player; 
		jointDef.bodyB = bodyB;
		jointDef.localAnchorA = new B2Vec2(0.0, 0.0); // Will cause mayhem, but let's just try it
		jointDef.localAnchorB = new B2Vec2(0.0, 0.0);
		var joint = world.createJoint(jointDef);
		return joint;
	}
}
