import flash.display.*;

class Game {
    static function main() {
    	var loader = new flash.display.Loader();
    	loader.contentLoaderInfo.addEventListener(flash.events.Event.COMPLETE, function(_) {
    		var game = new ProtectTheWall(untyped loader.content.bitmapData);
    	});
    	loader.load(new flash.net.URLRequest("sheet.png"));
    }
}