package objects;

import backend.animation.PsychAnimationController;

import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;

class StrumNote extends FlxSprite
{
	public var rgbShader:RGBShaderReference;
	public var resetAnim:Float = 0;
	private var noteData:Int = 0;
	public var direction:Float = 90;
	public var downScroll:Bool = false;
	public var sustainReduce:Bool = true;
	private var player:Int;
	
	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		if(texture != value) {
			texture = value;
			reloadNote();
		}
		return value;
	}

	public var useRGBShader:Bool = true;
	public function new(x:Float, y:Float, leData:Int, player:Int) {
		animation = new PsychAnimationController(this);

		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(leData));
		rgbShader.enabled = false;
		if(PlayState.SONG != null && PlayState.SONG.disableNoteRGB) useRGBShader = false;
		
		var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[leData];
		if(PlayState.isPixelStage) arr = ClientPrefs.data.arrowRGBPixel[leData];
		
		if(leData <= arr.length)
		{
			@:bypassAccessor
			{
				rgbShader.r = arr[0];
				rgbShader.g = arr[1];
				rgbShader.b = arr[2];
			}
		}

		noteData = leData;
		this.player = player;
		this.noteData = leData;
		this.ID = noteData;
		super(x, y);

		var skin:String = null;
		if(PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) skin = PlayState.SONG.arrowSkin;
		else skin = Note.defaultNoteSkin;

		texture = skin; //Load texture and anims
		scrollFactor.set();
		playAnim('static');
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;

		if (PlayState.isPixelStage)
		{
			var graph:flixel.graphics.FlxGraphic = Paths.image('pixelUI/$texture');
			loadGraphic(graph, true, Math.round(graph.width / 4), Math.round(graph.height / 5));
			scale.set(PlayState.daPixelZoom, PlayState.daPixelZoom); updateHitbox();
			antialiasing = false;

			switch (Math.abs(noteData) % 4)
			{
				case 0:
					animation.add('static', [0]);
					animation.add('pressed', [4, 8], 12, false);
					animation.add('confirm', [12, 16], 24, false);
				case 1:
					animation.add('static', [1]);
					animation.add('pressed', [5, 9], 12, false);
					animation.add('confirm', [13, 17], 24, false);
				case 2:
					animation.add('static', [2]);
					animation.add('pressed', [6, 10], 12, false);
					animation.add('confirm', [14, 18], 12, false);
				case 3:
					animation.add('static', [3]);
					animation.add('pressed', [7, 11], 12, false);
					animation.add('confirm', [15, 19], 24, false);
			}
		}
		else
		{
			frames = Paths.getSparrowAtlas(texture);
			scale.set(0.6, 0.6); updateHitbox();
			antialiasing = ClientPrefs.data.antialiasing;

			switch (Math.abs(noteData) % 4)
			{
				case 0:
					animation.addByPrefix('static', 'arrowLEFT', 24);
					animation.addByPrefix('pressed', 'left press', 24, false);
					animation.addByPrefix('confirm', 'left confirm', 24, false);
				case 1:
					animation.addByPrefix('static', 'arrowDOWN', 24);
					animation.addByPrefix('pressed', 'down press', 24, false);
					animation.addByPrefix('confirm', 'down confirm', 24, false);
				case 2:
					animation.addByPrefix('static', 'arrowUP', 24);
					animation.addByPrefix('pressed', 'up press', 24, false);
					animation.addByPrefix('confirm', 'up confirm', 24, false);
				case 3:
					animation.addByPrefix('static', 'arrowRIGHT', 24);
					animation.addByPrefix('pressed', 'right press', 24, false);
					animation.addByPrefix('confirm', 'right confirm', 24, false);
			}
			animation.onFinish.add((a) -> if (useRGBShader && a == "confirm")
				rgbShader.enabled = !rgbShader.enabled);
		}

		if (lastAnim != null) playAnim(lastAnim, true);
	}

	public inline function playerPosition()
	{
		x += (Note.swagWidth * noteData) + 50;
		x += ((FlxG.width / 2) * player);
	}

	override function update(elapsed:Float) {
		if(resetAnim > 0) {
			resetAnim -= elapsed;
			if(resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}
		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false)
	{
		animation.play(anim, force);
		if (animation.curAnim != null)
		{
			centerOffsets();
			centerOrigin();
		}

		rgbShader.enabled = useRGBShader && animation.curAnim?.name != 'static';
	}
}
