package substates;

import haxe.Json;
import options.OptionsState;
import backend.WeekData;

private typedef TextOpt = 
{
	id:String,
	defName:String,
	action:Void->Void
}

class TonhoPauseSubstate extends MusicBeatSubstate
{
	var options:Array<TextOpt> = [];
	var curSelected:Int = 0;

	var textGrp:FlxTypedSpriteGroup<FlxText> = new FlxTypedSpriteGroup<FlxText>();
	public static var music:FlxSound = new FlxSound();

	// Render stuff
	static var renderImg:flixel.graphics.FlxGraphic;
	@:unreflective static var protectRender:Bool;

	public function new(?camera:FlxCamera)
	{
		camera ??= FlxG.cameras.list[FlxG.cameras.list.length - 1];
		this.camera = camera;

		options = 
		[
			{id: "resume", defName: "Resumir", action: () -> getTFOut()},
			{id: "restart", defName: "Reiniciar", action: FlxG.resetState},
			{id: "options", defName: "Opções", action: function()
			{
				OptionsState.onPlayState = true;
				FlxG.switchState(() -> new OptionsState());
			}},
			{id: "back", defName: "Sair", action: function()
			{
				close();
				FlxG.switchState(() -> new states.MainMenuState());
			}}
		];
		
		super(0xB0000000);
	}

	@:unreflective
	@:noCompletion
	static inline function __forEachUsedImg(func:(imgPath:String)->Void)
	{
		for (i in ['images/pausescreen/bg.png', '${Language.getFileTranslation('images/pausescreen/info')}.png'])
			func(i);
	}

	public static function cacheStuff(targetSong:String, ?weekData:WeekData)
	{		
		weekData ??= WeekData.getCurrentWeek();
		weekData ??= new WeekData(cast Json.parse(Paths.getTextFromFile('weeks/mundoToras.json')), 'mundoToras'); // If PlayState week is null, we default to first week
		if (!Paths.fileExists('music/pause/$targetSong.${Paths.SOUND_EXT}', MUSIC)) targetSong = "breakfast"; 

		renderImg = Paths.image(weekData.renderPath);
		protectRender = weekData.renderPath.startsWith('mainmenu/renders/');
		music.loadEmbedded(Paths.music('pause/$targetSong'), true);

		__forEachUsedImg(function(img)
		{
			Paths.cacheBitmap(img);
			Paths.avoidDumping(img); // Just incase of someone using Paths.clearStoredMemory();
		});
	}

	public static function clearCache()
	{
		@:privateAccess final killGraphic:flixel.graphics.FlxGraphic->Void = Paths.destroyGraphic;

		__forEachUsedImg(function(img)
		{
			final path:String = Paths.getSharedPath(img);
			Paths.dumpExclusions.remove(path);

			killGraphic(Paths.currentTrackedAssets[path]);
			Paths.currentTrackedAssets.remove(path);
		});

		if (!protectRender) killGraphic(renderImg);
		music.destroy();
	}

	override function create()
	{
		super.create();
		FlxG.random.resetInitialSeed(); // Random randomized music position

		music.play(true, FlxG.random.float(0, (music.length / 2)));
		music.fadeIn(1.2, 0, 0.5);

		var bgGrid:flixel.addons.display.FlxBackdrop = new flixel.addons.display.FlxBackdrop(flixel.addons.display.FlxGridOverlay.createGrid(20, 20, 40, 40, true, FlxColor.WHITE, FlxColor.TRANSPARENT));
		bgGrid.scale.set(2.5, 2.5); bgGrid.updateHitbox();
		bgGrid.velocity.set(-24, 24);
		bgGrid.alpha = 0.13;
		add(bgGrid);

		var render:FlxSprite = new FlxSprite(0, 0, renderImg);
		render.scale.set(0.5, 0.5); render.updateHitbox();
		render.screenCenter(Y).x = (FlxG.width - render.width) - 120;
		add(render);

		__forEachUsedImg(function(imgPath)
		{
			var spr:FlxSprite = new FlxSprite(0, 0, Paths.getSharedPath(imgPath));
			spr.scale.set(0.67, 0.67); spr.updateHitbox();
			spr.screenCenter(Y);
			add(spr);
		});

		for (i=>o in options) _createText(i, o);
		textGrp.screenCenter(Y).x = 235;
		add(textGrp);

		changeSelection(0);
	}	

	function _createText(pos:Int, opt:TextOpt)
	{
		// Damn border getting cutoff
		var text:FlxText = new FlxText(0, 0, (FlxG.width / 2), ' ${Language.getPhrase('pause_${opt.id}', opt.defName)}', 76);
		text.font = Paths.font("fraiche.ttf");
		text.antialiasing = true;
		text.setBorderStyle(OUTLINE, FlxColor.BLACK, 4.2);
		text.y += (text.height + 12) * pos;
		text.active = false;
		textGrp.add(text);
	}

	override function update(elapsed:Float)
	{
		final up_p:Bool = controls.UI_UP_P;
		if (up_p || controls.UI_DOWN_P) changeSelection(1 * (up_p ? -1 : 1));

		if (controls.ACCEPT) options[curSelected].action();

		super.update(elapsed);
	}

	function changeSelection(change:Int)
	{
		textGrp.members[curSelected].color = FlxColor.WHITE;

		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);

		textGrp.members[curSelected].color = FlxColor.YELLOW;
	}

	function getTFOut(?finishFunc:Void->Void)
	{
		finishFunc ??= close;
		final twnEase = FlxEase.expoOut;
		music.fadeOut(0.4, 0, (_) -> music.pause());

		for (i=>s in members) FlxTween.tween(s, {alpha: 0}, 0.2, {ease: twnEase});
		FlxTween.num(bgColor.alphaFloat, 0, 0.2, {ease: twnEase, onComplete: (_) -> finishFunc()}, function(a)
		{
			bgColor.alphaFloat = a;
			bgColor = bgColor;
		});
	}
}