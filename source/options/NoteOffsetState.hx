package options;

import substates.TonhoPauseSubstate;
import backend.StageData;
import objects.Character;
import objects.Bar;
import states.stages.StageWeek1 as BackgroundStage;

class NoteOffsetState extends MusicBeatState
{
	var stageData:StageFile;
	var boyfriend:Character;
	var gf:Character;

	public var camGame:FlxCamera;
	public var camHUD:FlxCamera;
	public var camOther:FlxCamera;

	var barPercent:Float = 0;
	var delayMin:Int = -500;
	var delayMax:Int = 500;
	var timeBar:Bar;
	var timeTxt:FlxText;
	var beatText:Alphabet;
	var beatTween:FlxTween;
	var zoomTween:FlxTween;

	var holdTime:Float = 0;

	override function create()
	{
		#if DISCORD_ALLOWED DiscordClient.changePresence("Audio Offset Menu"); #end
		TonhoPauseSubstate.music.pause();
		FlxG.sound.playMusic(Paths.music('offsetSong'));
		Conductor.bpm = 128;

		// Cameras
		camGame = initPsychCamera();

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		camOther = new FlxCamera();
		camOther.bgColor.alpha = 0;
		FlxG.cameras.add(camOther, false);

		// Stage
		stageData = StageData.getStageFile("stage");
		Paths.currentLevel = stageData.directory;

		new BackgroundStage();
		FlxG.camera.scroll.set(120, 100);

		// Characters
		if (!stageData.hide_girlfriend)
		{
			gf = new Character(stageData.girlfriend[0], stageData.girlfriend[1], stageData._editorMeta?.gf ?? 'morana');
			gf.x += gf.positionArray[0]; gf.y += gf.positionArray[1];
			gf.scrollFactor.set(0.95, 0.95);
			add(gf);
		}

		boyfriend = new Character(stageData.boyfriend[0], stageData.boyfriend[1], stageData._editorMeta?.boyfriend ?? 'bf', true);
		boyfriend.x += boyfriend.positionArray[0]; boyfriend.y += boyfriend.positionArray[1];
		add(boyfriend);

		// Note delay stuff
		beatText = new Alphabet(0, 0, Language.getPhrase('delay_beat_hit', 'Batida!'), true);
		beatText.setScale(0.6, 0.6);
		beatText.x += 260;
		beatText.alpha = 0;
		beatText.acceleration.y = 250;
		add(beatText);
		
		barPercent = ClientPrefs.data.noteOffset;
		timeBar = new Bar(0, FlxG.height - 120, 'timeBar', () -> barPercent, delayMin, delayMax);
		timeBar.leftBar.color = FlxColor.LIME;
		timeBar.camera = camHUD;
		timeBar.screenCenter(X);
		timeBar.scrollFactor.set();
		add(timeBar);

		timeTxt = new FlxText(0, 0, timeBar.width);
		timeTxt.setFormat(Paths.font("fraiche.ttf"), 32, FlxColor.WHITE, CENTER);
		timeTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		timeTxt.camera = camHUD;
		timeTxt.screenCenter(X).y = (timeBar.y + (timeBar.height / 2)) - (timeTxt.height / 2);
		timeTxt.antialiasing = true;
		timeTxt.scrollFactor.set();
		add(timeTxt);

		updateNoteDelay();
		super.create();
		#if mobile
		addVpad(LEFT_RIGHT, CUSTOM(["a", "back", "c"], ["accept", "back", "shift"]));
		addVpadCam();

		virtualPad.otherButtons["back"].setPosition(FlxG.width - virtualPad.otherButtons["back"].width, 0);
		virtualPad.otherButtons["a"].setPosition(
			(FlxG.width - virtualPad.otherButtons["a"].width) - mobile.VirtualPadHandler.NICE_OFFSET,
			(FlxG.height - virtualPad.otherButtons["a"].height) - mobile.VirtualPadHandler.NICE_OFFSET
		);
		virtualPad.otherButtons["c"].setPosition(
			(virtualPad.otherButtons["a"].x - virtualPad.otherButtons["a"].width) - mobile.VirtualPadHandler.NICE_OFFSET,
			virtualPad.otherButtons["a"].y
		);
		#end
	}

	override function update(elapsed:Float)
	{
		final addNum:Int = (FlxG.keys.pressed.SHIFT || FlxG.gamepads.anyPressed(LEFT_SHOULDER)) ? 3 : 1;

		if (controls.UI_LEFT_P)
		{
			barPercent = Math.max(delayMin, Math.min(ClientPrefs.data.noteOffset - 1, delayMax));
			updateNoteDelay();
		}
		else if (controls.UI_RIGHT_P)
		{
			barPercent = Math.max(delayMin, Math.min(ClientPrefs.data.noteOffset + 1, delayMax));
			updateNoteDelay();
		}

		var mult:Int = 1;
		if (controls.UI_LEFT || controls.UI_RIGHT)
		{
			holdTime += elapsed;
			if (controls.UI_LEFT) mult = -1;
		}

		if (controls.UI_LEFT_R || controls.UI_RIGHT_R) holdTime = 0;

		if (holdTime > 0.5)
		{
			barPercent += 100 * addNum * elapsed * mult;
			barPercent = Math.max(delayMin, Math.min(barPercent, delayMax));
			updateNoteDelay();
		}

		if (controls.RESET)
		{
			holdTime = 0;
			barPercent = 0;
			updateNoteDelay();
		}

		if (controls.BACK)
		{
			zoomTween?.cancel();
			beatTween?.cancel();

			FlxG.switchState(() -> new OptionsState());
			if (OptionsState.onPlayState) TonhoPauseSubstate.music.resume();
			else CoolUtil.playMenuSongForce();
		}

		Conductor.songPosition = FlxG.sound.music.time;
		super.update(elapsed);
	}

	override function beatHit()
	{
		super.beatHit();

		if (curBeat % 2 == 0)
		{
			boyfriend.dance();
			gf.dance();
		}
		
		if (curBeat % 4 == 2)
		{
			FlxG.camera.zoom *= 1.15;
			if (zoomTween?.active) zoomTween.cancel();
			zoomTween = FlxTween.tween(FlxG.camera, {zoom: stageData.defaultZoom}, 1, {ease: FlxEase.circOut, onComplete: (twn) -> twn = null});

			beatText.alpha = 1;
			beatText.y = 320;
			beatText.velocity.y = -150;
			if (beatTween?.active) beatTween.cancel();
			beatTween = FlxTween.tween(beatText, {alpha: 0}, 1, {ease: FlxEase.sineIn, onComplete: (twn) -> twn = null});
		}
	}

	inline function updateNoteDelay()
	{
		ClientPrefs.data.noteOffset = Math.round(barPercent);
		timeTxt.text = Language.getPhrase('delay_current_offset', 'Atraso atual: {1}MS', [Math.floor(barPercent)]);
	}
}
