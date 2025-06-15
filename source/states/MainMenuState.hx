package states;

import backend.WeekData;
import backend.Song;
import tjson.TJSON;
import haxe.Json;
import flixel.util.typeLimit.NextState;
import openfl.display.BitmapData;
import flixel.util.FlxGradient;
import flixel.addons.display.FlxGridOverlay;
import flixel.effects.FlxFlicker;
import options.OptionsState;

private enum abstract AlignType(String) from String 
{
	final CENTER:String = "centered";
	final BOTTOM_LEFT:String = "bottomL";
	final BOTTOM_RIGHT:String = "bottomR";
	final TOP_LEFT:String = "topL";
	final TOP_RIGHT:String = "topR";
}

private typedef RenderData = 
{
	imageName:String,
	offset:Array<Float>,
	scale:Float,
	?originAlign:AlignType
}

private typedef MenuOpt = 
{
	offset:Array<Float>,
	scale:Float,
	render:RenderData
}

class MainMenuState extends MusicBeatState
{
	public static final psychEngineVersion:String = '1.0.4';
	static var showOutdatedWarning:Bool = true;

	public static var curSelected:Int = 0;
	var selectedSomethin:Bool = false;

	final datasPath:String = 'menus/main/';
	var menuItems:FlxTypedGroup<FlxSprite>;
	var optionShit:Array<String> = [];

	var menuColors:Array<FlxColor> = [];
	var bgGrad:FlxSprite;

	var renderSprs:Array<FlxSprite> = [];
	// Neat bopping effect
	var renderScales:Array<Float> = [];
	final bopInterval:Int = 2;
	final lerpSpeed:Float = 6;

	override function create()
	{
		optionShit = CoolUtil.coolTextFile(Paths.txt('${datasPath}list'));
		if (optionShit.length == 0)
		{
			selectedSomethin = true;
			FlxTransitionableState.skipNextTransOut = true;
			FlxTransitionableState.skipNextTransIn = true;

			FlxG.switchState(function() 
			{
				return new ErrorState(
					'No menu items were found!! You can fix this by adding one in "./data/${datasPath}menuList.txt".\nPress ACCEPT to reload | Press BACK to back out',
					() -> FlxG.switchState(() -> new MainMenuState()),
					() -> FlxG.switchState(() -> new TitleState())
				);
			});
			return;
		}

		super.create();
		#if DISCORD_ALLOWED DiscordClient.changePresence("In the Menus"); #end

		var bg:FlxSprite = new FlxSprite(0, 0, Paths.image('menuBG'));
		bg.screenCenter();
		bg.flipX = true;
		bg.active = false;
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		bgGrad = new FlxSprite(0, 0, FlxGradient.createGradientBitmapData(200, 120, [0xFFADADAD, 0xFF3F3F3F]));
		bgGrad.setGraphicSize(FlxG.width, FlxG.height); bgGrad.updateHitbox();
		bgGrad.screenCenter();
		bgGrad.active = false;
		bgGrad.antialiasing = false;
		bgGrad.blend = MULTIPLY; // screen
		add(bgGrad);

		var bgGrid:flixel.addons.display.FlxBackdrop = new flixel.addons.display.FlxBackdrop(FlxGridOverlay.createGrid(20, 20, 40, 40, true, FlxColor.WHITE, FlxColor.TRANSPARENT));
		bgGrid.scale.set(1.85, 1.85); bgGrid.updateHitbox();
		bgGrid.velocity.set(-24, 24);
		bgGrid.alpha = 0.13;
		add(bgGrid);

		menuItems = new FlxTypedGroup<FlxSprite>();
		for (o in optionShit)
		{
			final optData:MenuOpt = Json.parse(Paths.getTextFromFile('data/${datasPath}opt_$o.json'));

			var item:FlxSprite = createMenuItem(o, 30, -200, optData);
			menuColors.push(CoolUtil.dominantColor(item));

			createRender(optData.render);
		}

		var overlay:FlxSprite = new FlxSprite(0, 0, Paths.image('mainmenu/overlay'));
		overlay.setGraphicSize(FlxG.width, FlxG.height); overlay.updateHitbox();
		overlay.screenCenter();
		overlay.active = false;
		overlay.antialiasing = ClientPrefs.data.antialiasing;
		add(overlay);
		add(menuItems);

		var psychVer:FlxText = new FlxText(0, 0, 0, 'Funkin\' Verade V${lime.app.Application.current.meta["version"]}\nPsych V$psychEngineVersion');
		psychVer.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		psychVer.setPosition(
			(FlxG.width - psychVer.width) - psychVer.size, 
			(FlxG.height - psychVer.height) - psychVer.size
		);
		psychVer.active = false;
		add(psychVer);

		changeItem(0);

		#if CHECK_FOR_UPDATES
		if (showOutdatedWarning && ClientPrefs.data.checkForUpdates && substates.OutdatedSubState.updateVersion != psychEngineVersion) {
			persistentUpdate = false;
			showOutdatedWarning = false;
			openSubState(new substates.OutdatedSubState());
		}
		#end
	}

	function createMenuItem(name:String, x:Float, y:Float, data:MenuOpt):FlxSprite
	{
		final defScale:Float = 1.35 / optionShit.length;

		var spr:FlxSprite = new FlxSprite(x, y);
		spr.frames = Paths.getSparrowAtlas('mainmenu/options/$name', false);
		spr.animation.addByPrefix('idle', 'NaoSelecionado', 0, false);
		spr.animation.addByPrefix('selected', 'Selecionado', 24);
		spr.animation.play('idle');

		spr.scale.set(defScale * data.scale, defScale * data.scale); spr.updateHitbox();
		spr.y += ((spr.height * spr.scale.y) * optionShit.indexOf(name)) + 90;
		spr.offset.add(-data.offset[0], -data.offset[1]);
		
		spr.antialiasing = ClientPrefs.data.antialiasing;
		menuItems.add(spr);
		return spr;
	}

	function createRender(data:RenderData)
	{
		data.originAlign ??= AlignType.CENTER;

		var spr:FlxSprite = new FlxSprite(FlxG.width / 2.5, 0, Paths.image('mainmenu/renders/${data.imageName}'));
		spr.scale.set(data.scale, data.scale); spr.updateHitbox();
		spr.screenCenter(Y);
		spr.active = false;
		spr.visible = false;
		spr.antialiasing = true;

		final originOffsets:Array<Float> = switch (data.originAlign)
		{
			case CENTER: [0.5, 0.5];
			case BOTTOM_LEFT: [0.2, 0.8];
			case BOTTOM_RIGHT: [0.8, 0.8];
			case TOP_LEFT: [0.2, 0.2];
			case TOP_RIGHT: [0.8, 0.2];
		};
		spr.origin.set(spr.frameWidth * originOffsets[0], spr.frameHeight * originOffsets[1]);
		spr.offset.set(-data.offset[0], -data.offset[1]);

		renderSprs.push(spr);
		renderScales.push(data.scale);
		add(spr);
	}

	override function update(elapsed:Float)
	{
		if (selectedSomethin)
		{
			super.update(elapsed);
			return;
		}
		if (FlxG.sound.music?.playing) Conductor.songPosition = FlxG.sound.music.time;

		final up_p:Bool = controls.UI_UP_P;
		if (up_p || controls.UI_DOWN_P)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'));
			changeItem(1 * (up_p ? -1 : 1));
		}

		if (controls.BACK) selectItem("exit");
		if (controls.ACCEPT) selectItem(optionShit[curSelected]);

		#if (debug && desktop)
		if (FlxG.keys.justPressed.F5) FlxG.resetState();

		if (controls.justPressed('debug_1'))
		{
			selectedSomethin = true;

			var editorsMenu:flixel.FlxSubState = new states.editors.MasterEditorMenu();
			editorsMenu.closeCallback = () -> selectedSomethin = false;
			openSubState(editorsMenu);
		}
		#end

		super.update(elapsed);
		// if (!renderSprs[curSelected]?.visible) return;

		renderSprs[curSelected].scale.set(
			FlxMath.lerp(renderScales[curSelected], renderSprs[curSelected].scale.x, Math.exp(-elapsed * lerpSpeed)),
			FlxMath.lerp(renderScales[curSelected], renderSprs[curSelected].scale.y, Math.exp(-elapsed * lerpSpeed))
		);
	}

	override function beatHit()
	{
		if (curBeat % bopInterval != 0) return;
		renderSprs[curSelected].scale.add(0.042, 0.042);
	}

	function changeItem(change:Int)
	{
		menuItems.members[curSelected].animation.play("idle");
		renderSprs[curSelected].visible = false;

		curSelected = FlxMath.wrap(curSelected + change, 0, optionShit.length - 1);
		menuItems.members[curSelected].animation.play("selected");

		renderSprs[curSelected].visible = true;
		bgGrad.color = menuColors[curSelected];
	}

	function selectItem(choice:String)
	{
		var instant:Bool = false;
		var sound:String = "confirmMenu";
		var needsPreload:Bool = false;
		var preloadPrep:Void->Void = null;

		switch (choice)
		{
			#if release
			case "story":
				WeekData.reloadWeekFiles(true); // weeksList doesn't get set until we do this
				PlayState.storyPlaylist = ["irmaos-de-frutas"];
				PlayState.isStoryMode = true;

				Song.loadFromJson("irmaos-de-frutas");
				PlayState.campaignScore = 0;
				PlayState.campaignMisses = 0;

				needsPreload = true;
				preloadPrep = LoadingState.prepareToSong;
			#end
			case "exit":
				sound = "cancelMenu";
				instant = true;
		}

		final state:NextState = switch (choice)
		{
			#if release
			case "story": () -> new PlayState();
			#else
			case "story": () -> new FreeplayState();
			#end
			case "credits": () -> new CreditsState();
			case "settings": () -> new OptionsState();
			case "exit": () -> new TitleState();
			default: null;
		};

		if (state == null)
		{
			FlxG.log.warn('"$choice" doesn\'t do anything');

			FlxG.sound.play(Paths.sound("cancelMenu"));
			return;
		}

		selectedSomethin = true;
		if (instant)
		{
			FlxG.sound.play(Paths.sound(sound));

			__getToNextState(state, needsPreload, preloadPrep);
			return;
		}

		FlxG.sound.play(Paths.sound(sound));
		FlxFlicker.flicker(menuItems.members[curSelected], 1, 0.06, true, true, (_) -> __getToNextState(state, needsPreload, preloadPrep));
		for (p=>i in menuItems)
		{
			if (p == curSelected) continue;
			FlxTween.tween(i, {alpha: 0}, 0.4, {ease: FlxEase.quadOut});
		}	
	}

	@:noCompletion
	function __getToNextState(state:NextState, needsPreload:Bool, preloadPrep:Null<Void->Void>)
	{
		if (!needsPreload)
		{
			FlxG.switchState(state);
			return;
		}

		if (preloadPrep != null) preloadPrep();
		LoadingState.loadAndSwitchState(state.createInstance());
	}
}