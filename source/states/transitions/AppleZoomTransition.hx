package states.transitions;

import flixel.addons.transition.TransitionData;

class AppleZoomTransition extends flixel.FlxSubState
{
	var transIn:Bool = false;
	static var _customCamera:FlxCamera;
	static var __customCamInitialized:Bool = false;

	var __data:TransitionData;
	var trans:FlxSprite;

	public function new(data:TransitionData, transIn:Bool)
	{
		this.transIn = transIn;
		__data = data;
		super();

		switch (__data.cameraMode)
		{
			case TOP: camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];
			case DEFAULT: camera = _parentState.camera;
			case NEW:
				if (!__customCamInitialized)
				{
					_customCamera = new FlxCamera(0, 0, FlxG.width, FlxG.height);
					__customCamInitialized = true;
				}
				camera = _customCamera;
		}
	}

	override function create()
	{
		super.create();

		trans = new FlxSprite();
		trans.frames = Paths.getSparrowAtlas('transitions/appleTrans');
		trans.animation.addByPrefix('trans', 'bizarro da silva', 30, false);
		trans.setGraphicSize(FlxG.width, FlxG.height); trans.updateHitbox();
		trans.screenCenter();
		trans.scrollFactor.set();
		add(trans);

		trans.animation.play('trans', true, transIn);
		trans.animation.onFinish.addOnce((_) -> closeCallback());
	}
}