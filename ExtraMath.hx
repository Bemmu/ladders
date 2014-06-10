class ExtraMath {
	// http://stackoverflow.com/questions/849211/shortest-distance-between-a-point-and-a-line-segment
	public static function sqr(x:Float):Float {
		return x * x;
	}
	public static function dist2(a:Point, b:Point):Float { 
		return sqr(a.x - b.x) + sqr(a.y - b.y);
	}
	public static function distToSegmentSquared(p:Point, v:Point, w:Point) {
		var l2:Float = dist2(v, w);
		if (l2 == 0) return [0, dist2(p, v)];
		var t:Float = ((p.x - v.x) * (w.x - v.x) + (p.y - v.y) * (w.y - v.y)) / l2;
		if (t < 0) return [0, dist2(p, v)];
		if (t > 1) return [1, dist2(p, w)];
		return [t, dist2(p, new Point(v.x + t * (w.x - v.x), v.y + t * (w.y - v.y)))];
	}
	public static function distToSegment(p, v, w) { 
		var ret = distToSegmentSquared(p, v, w); 
		return [ret[0], Math.sqrt(ret[1])]; 
	}	
}