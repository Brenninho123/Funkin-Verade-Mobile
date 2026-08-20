package states;

import flixel.util.FlxGradient;
import flixel.input.keyboard.FlxKey;
import flixel.group.FlxGroup;
import openfl.display.BitmapData;
import states.MainMenuState;

class TitleState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	var blockInput:Bool = false;
	public static var skippedIntro:Bool = false;

	var logo:FlxSprite;
	var titleText:FlxSprite;
	var chars:Array<FlxSprite> = []; // I REFUSE to create another group, they're too much of a hassle!
	final bopInterval:Int = 2;
	final lerpSpeed:Float = 4.4;

	var credCam:FlxCamera;
	var credGroup:FlxGroup = new FlxGroup();
	var textGroup:FlxGroup = new FlxGroup();
	var curWacky:Array<String> = [];

	override function create()
	{
		FlxG.mouse.visible = false;
		#if DISCORD_ALLOWED DiscordClient.changePresence("Watching the Title Screen", null, true); #end
		super.create();

		initSprites();
		if (skippedIntro)
		{
			CoolUtil.playMenuSong();
			return;
		}

		curWacky = FlxG.random.getObject(getIntroTextShit());
		initIntro();
	}

	function initSprites()
	{
		var bg:FlxSprite = new FlxSprite();

		// Fixes going to TitleState after another state used this image (destroyed bitmap crash)
		FlxG.bitmap.remove(Paths.currentTrackedAssets['images/veradeBG.png']);
		Paths.currentTrackedAssets.remove('images/veradeBG.png');

		final bmp:BitmapData = Paths.image('veradeBG', ClientPrefs.data.lowQuality).bitmap; // Separate var just to avoid applying the filter on this
		if (!ClientPrefs.data.lowQuality)
		{
			var bmpClone:BitmapData = bmp.clone();
			bmpClone.applyFilter(bmpClone, bmp.rect, new openfl.geom.Point(), new openfl.filters.BlurFilter(1.5, 1.5, 2));
			bmpClone = FlxGradient.overlayGradientOnBitmapData(bmpClone, bmp.width, bmp.height, [0xA84BF57B, 0xA8BD5AE8]);
			bg.loadGraphic(bmpClone);
		}
		else bg.loadGraphic(bmp);

		bg.screenCenter();
		bg.active = false;
		bg.antialiasing = false;
		add(bg);

		if (!ClientPrefs.data.lowQuality)
		{
			var bgGrid:flixel.addons.display.FlxBackdrop = new flixel.addons.display.FlxBackdrop(flixel.addons.display.FlxGridOverlay.createGrid(20, 20, 40, 40, true, FlxColor.WHITE, FlxColor.TRANSPARENT));
			bgGrid.scale.set(1.85, 1.85); bgGrid.updateHitbox();
			bgGrid.velocity.set(-24, 24);
			bgGrid.alpha = 0.13;
			add(bgGrid);
		}

		// Since they're the same frame length, we can reuse the same array and save some mem and some typing	
		var leftBopAnim:Array<Int> = CoolUtil.numberArray(14);
		var rightBopAnim:Array<Int> = CoolUtil.numberArray(30, 15);

		var blueyBop:FlxSprite = new FlxSprite(385, 405);
		blueyBop.frames = Paths.getSparrowAtlas('titlescreen/chars/blfi');
		blueyBop.animation.addByIndices('danceLeft', 'blfi', leftBopAnim, "", 24, false);
		blueyBop.animation.addByIndices('danceRight', 'blfi', rightBopAnim, "", 24, false);
		blueyBop.scale.set(0.5, 0.5); blueyBop.updateHitbox();

		var mornaaBop:FlxSprite = new FlxSprite((blueyBop.x + blueyBop.width) - 75, blueyBop.y - 25);
		mornaaBop.frames = Paths.getSparrowAtlas('titlescreen/chars/mona');
		mornaaBop.animation.addByPrefix('idle', 'mona', 24, false);
		mornaaBop.scale.set(0.53, 0.53); mornaaBop.updateHitbox();
		chars.push(mornaaBop);
		chars.push(blueyBop);
		
		var tonhoBop:FlxSprite = new FlxSprite(20, 100);
		tonhoBop.frames = Paths.getSparrowAtlas('titlescreen/chars/tojo');
		tonhoBop.animation.addByIndices('danceLeft', 'tojo', leftBopAnim, "", 24, false);
		tonhoBop.animation.addByIndices('danceRight', 'tojo', rightBopAnim, "", 24, false);
		tonhoBop.scale.set(0.5, 0.5); tonhoBop.updateHitbox();
		chars.push(tonhoBop);

		var morjoBop:FlxSprite = new FlxSprite(FlxG.width, tonhoBop.y);
		morjoBop.frames = Paths.getSparrowAtlas('titlescreen/chars/mojo');
		morjoBop.animation.addByPrefix('idle', 'mojo', 24, false);
		morjoBop.scale.set(0.5, 0.5); morjoBop.updateHitbox();
		morjoBop.x -= morjoBop.width + (40 + tonhoBop.x);
		chars.push(morjoBop);

		logo = new FlxSprite(0, 0, Paths.image('titlescreen/logo'));
		logo.scale.set(0.34, 0.34); logo.updateHitbox();
		logo.screenCenter().y -= 155;
		logo.active = false;
		logo.antialiasing = ClientPrefs.data.antialiasing;

		for (s in chars) add(s);
		leftBopAnim.resize(0);
		rightBopAnim.resize(0);

		add(logo);

		titleText = new FlxSprite();
		titleText.frames = Paths.getSparrowAtlas('titlescreen/titleEnter');
		titleText.animation.addByPrefix('idle', "ENTER IDLE", 0, false);
		titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		titleText.animation.play('idle');
		titleText.screenCenter(X).y = (FlxG.height - titleText.height) - 25;
		titleText.color = FlxColor.BLACK;
		titleText.antialiasing = true;
		add(titleText);
	}

	inline function initIntro()
	{
		credCam = new FlxCamera(0, 0, FlxG.width, FlxG.height);
		FlxG.cameras.add(credCam, false);
		
		credGroup.camera = credCam;
		add(credGroup);

		textGroup.camera = credCam;
		add(textGroup);

		var we:FlxSprite = createCoolSprite(0, 132, 'avalanche');
		we.scale.set(0.4, 0.4); we.updateHitbox();
		we.screenCenter(X);

		CoolUtil.playMenuSongForce(4);
	}
	
	inline function getIntroTextShit():Array<Array<String>>
	{
		return [for (t in CoolUtil.coolTextFile('data/${Language.getFileTranslation('menus/introText')}.txt')) t.split("--")];
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music?.playing) Conductor.songPosition = FlxG.sound.music.time;

		if (skippedIntro)
		{
			logo.scale.set(
				FlxMath.lerp(0.34, logo.scale.x, Math.exp(-elapsed * lerpSpeed)),
				FlxMath.lerp(0.34, logo.scale.y, Math.exp(-elapsed * lerpSpeed))
			); logo.updateHitbox();
			logo.y = (logo.screenCenter().y - 155);
		}

		if (blockInput)
		{
			super.update(elapsed);
			return;
		}

		if (FlxG.keys.justPressed.ENTER 
		#if FLX_TOUCH || FlxG.touches.getFirst()?.justPressed #end
		|| (FlxG.gamepads.lastActive?.justPressed.START || FlxG.gamepads.lastActive?.justPressed.A))
			enterPress();

		super.update(elapsed);
	}

	function createCoolSprite(x:Float, y:Float, image:String, ?sheetUser:Bool = false):FlxSprite
	{
		// if (!image.startsWith("titlescreen/")) image = 'titlescreen/$image';

		var spr:FlxSprite = new FlxSprite(x, y);
		switch (sheetUser)
		{
			case false: spr.loadGraphic(Paths.image(image));
			case true:
				spr.frames = Paths.getAtlas(image);
				spr.animation.addByPrefix('anim', haxe.io.Path.withoutDirectory(image), 24);
				spr.animation.play('anim');
		}
		spr.antialiasing = ClientPrefs.data.antialiasing;

		credGroup.add(spr);
		return spr;
	}

	function createCoolText(textArray:Array<String>, ?offset:Float = 0)
	{
		if (textArray.length == 1)
		{
			addMoreText(textArray[0], offset);
			return;
		}

		for (i=>t in textArray) __makeText(i, offset, t);
	}

	inline function addMoreText(text:String, ?offset:Float = 0)
	{
		__makeText(textGroup.length, offset, text);
	}

	function deleteCoolText(?deleteImagesOnly:Bool = false)
	{
		if (!deleteImagesOnly)
		{
			for (t in textGroup) t.destroy();
			textGroup.clear();
		}

		if (!credGroup.visible) return;

		for (s in credGroup) s.destroy();
		credGroup.clear();
		credGroup.visible = false;
	}

	function skipIntro()
	{
		if (skippedIntro) return;
		skippedIntro = true;

		FlxG.cameras.remove(credCam);
		deleteCoolText();
		for (g in [credGroup, textGroup])
		{
			g.destroy();
			remove(g, true);
		}

		FlxG.camera.flash(ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 4);
	}

	function charBop(beat:Int)
	{
		if (chars.length == 0) return;
		for (c in chars)
		{
			final danceIdle:Bool = !c.animation.exists("idle");
			final interval:Int = !danceIdle ? bopInterval : Math.round(bopInterval / 2);
			if (beat % interval != 0) continue;

			final anim:String = !danceIdle ? "idle" : (c.animation.name.endsWith("Left") ? "danceRight" : "danceLeft");
			c.animation.play(anim, true);
		}
	}

	override function beatHit()
	{
		super.beatHit();
		if (skippedIntro)
		{
			final add:Float = (curBeat % 2 == 0) ? -0.05 : 0.05;
			logo.scale.add(add, add);
			charBop(curBeat);
			return;
		}

		var hasWackyImage:Bool = curWacky[1].startsWith(":png:") || (curWacky.length > 2 && curWacky[2].startsWith(":png:"));
		var secondWacky:Bool = hasWackyImage && !curWacky[1].startsWith(":png:");

		switch (curBeat)
		{
			case 3: addMoreText('apresenta', 270);
			case 4:
				deleteCoolText();

				var tonho:FlxSprite = createCoolSprite(0, 0, 'titlescreen/tonho');
				tonho.scale.set(0.35, 0.35); tonho.updateHitbox();
				tonho.screenCenter();
			case 5: createCoolText(['O Torajo'], -45);
			case 7:
				credGroup.visible = true;
				addMoreText('faz uma live ae', 235);

			case 8:
				deleteCoolText();

				var ng:FlxSprite = createCoolSprite(0, 0, 'titlescreen/newgrounds_logo');
				ng.scale.set(0.35, 0.35); ng.updateHitbox();
				ng.screenCenter().y += 75;
			case 9: createCoolText(['FNF Original feito pela galera na'], -20);
			case 10: credGroup.visible = true;

			case 11:
				deleteCoolText();

				if (hasWackyImage)
				{
					final imgStr:String = curWacky[secondWacky ? 2 : 1].substr(5);
					var wackyImage:FlxSprite = createCoolSprite(0, 0, imgStr, Paths.fileExists('images/$imgStr.xml', TEXT));
					wackyImage.scale.set(0.35, 0.35); wackyImage.updateHitbox();
					wackyImage.screenCenter();
					if (secondWacky) wackyImage.y = (FlxG.height - wackyImage.height);
					wackyImage.y -= 90;
				}

				createCoolText([curWacky[0]]);
				credGroup.visible = !secondWacky;
			case 12:
				if (!secondWacky) deleteCoolText(true);

				var theWacky:String = (!secondWacky && hasWackyImage) ? (curWacky[2] ?? "...isso aí, eu acho..") : curWacky[1];
				addMoreText(theWacky);
				credGroup.visible = secondWacky;
			case 13:
				deleteCoolText();

				addMoreText('Funkin\'');
			case 14: addMoreText('em');
			case 15: addMoreText('Verade');
			case 16: skipIntro();
		}
	}

	function enterPress()
	{
		if (!skippedIntro)
		{
			skipIntro();
			return;
		}

		blockInput = true;
		titleText.animation.play('press');
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

		FlxTimer.wait(1, () -> 
			FlxG.switchState(() -> new MainMenuState()));
	}

	@:noCompletion
	function __makeText(pos:Int, offset:Float, text:String)
	{
		var textSpr:FlxText = new FlxText(0, (60 * pos) + (200 + offset), 0, text, 76);
		textSpr.font = Paths.font("fraiche.ttf");
		textSpr.textField.multiline = false;
		textSpr.textField.wordWrap = false;
		textSpr.screenCenter(X);
		textSpr.active = false;
		textSpr.antialiasing = ClientPrefs.data.antialiasing;
		textGroup.add(textSpr);
	}
}