package;

#if desktop
import Discord.DiscordClient;
import sys.thread.Thread;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import haxe.Json;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
import options.GraphicsSettingsSubState;
//import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.system.ui.FlxSoundTray;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import openfl.Assets;

using StringTools;
typedef TitleData =
{
	
	titlex:Float,
	titley:Float,
	startx:Float,
	starty:Float,
	gfx:Float,
	gfy:Float,
	backgroundSprite:String,
	bpm:Int
}
class TitleState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public static var initialized:Bool = false;

	var blackScreen:FlxSprite;
	var credGroup:FlxGroup;
	var credTextShit:Alphabet;
	var textGroup:FlxGroup;
	var ngSpr:FlxSprite;
	 var typeSound:FlxSound;

	var curWacky:Array<String> = [];

	var wackyImage:FlxSprite;

	#if TITLE_SCREEN_EASTER_EGG
	var easterEggKeys:Array<String> = [
		'ROCKET', 'CARROT', 'MAKESHIP', 'APLAPLAC', 'JUSTICE', 'VINNY', 'HEARTACHES', 'CLASSIC', 'FUN', 'BUCKET'
	];
	var allowedKeys:String = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
	var easterEggKeysBuffer:String = '';
	#end

	var mustUpdate:Bool = false;
	
	var titleJSON:TitleData;
	
	public static var updateVersion:String = '';

	override public function create():Void
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		// Just to load a mod on start up if ya got one. For mods that change the menu music and bg
		WeekData.loadTheFirstEnabledMod();
		
		//trace(path, FileSystem.exists(path));

		/*#if (polymod && !html5)
		if (sys.FileSystem.exists('mods/')) {
			var folders:Array<String> = [];
			for (file in sys.FileSystem.readDirectory('mods/')) {
				var path = haxe.io.Path.join(['mods/', file]);
				if (sys.FileSystem.isDirectory(path)) {
					folders.push(file);
				}
			}
			if(folders.length > 0) {
				polymod.Polymod.init({modRoot: "mods", dirs: folders});
			}
		}
		#end*/
		
		
		
		#if CHECK_FOR_UPDATES
		if(!closedState) {
			trace('checking for update');
			var http = new haxe.Http("https://raw.githubusercontent.com/ShadowMario/FNF-PsychEngine/main/gitVersion.txt");
			
			http.onData = function (data:String)
			{
				updateVersion = data.split('\n')[0].trim();
				var curVersion:String = MainMenuState.psychEngineVersion.trim();
				trace('version online: ' + updateVersion + ', your version: ' + curVersion);
				if(updateVersion != curVersion) {
					trace('versions arent matching!');
					mustUpdate = true;
				}
			}
			
			http.onError = function (error) {
				trace('error: $error');
			}
			
			http.request();
		}
		#end

		FlxG.game.focusLostFramerate = 60;
		FlxG.sound.muteKeys = muteKeys;
		FlxG.sound.volumeDownKeys = volumeDownKeys;
		FlxG.sound.volumeUpKeys = volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];

		PlayerSettings.init();

		curWacky = FlxG.random.getObject(getIntroTextShit());

		// DEBUG BULLSHIT

		swagShader = new ColorSwap();
		super.create();

		FlxG.save.bind('funkin', 'ninjamuffin99');
		
		ClientPrefs.loadPrefs();
		
		Highscore.load();

		// IGNORE THIS!!!
		titleJSON = Json.parse(Paths.getTextFromFile('images/gfDanceTitle.json'));
		
		#if TITLE_SCREEN_EASTER_EGG
		if (FlxG.save.data.psychDevsEasterEgg == null) FlxG.save.data.psychDevsEasterEgg = ''; //Crash prevention
		switch(FlxG.save.data.psychDevsEasterEgg.toUpperCase())
		{
			case 'ROCKET':
				titleJSON.gfx += 210;
				titleJSON.gfy += 40;
			case 'BUCKET':
				titleJSON.gfx += 210;
				titleJSON.gfy += 40;
			case 'CARROT':
				titleJSON.gfx += 210;
				titleJSON.gfy += 40;
			case 'MAKESHIP':
				titleJSON.gfx += 210;
				titleJSON.gfy += 40;
			case 'APLAPLAC':
				titleJSON.gfx += 210;
				titleJSON.gfy += 40;
			case 'JUSTICE':
				titleJSON.gfx += 210;
				titleJSON.gfy += 40;
			case 'VINNY':
				titleJSON.gfx += 210;
				titleJSON.gfy += 40;
			case 'HEARTACHES':
				titleJSON.gfx += 210;
				titleJSON.gfy += 40;
			case 'CLASSIC':
				titleJSON.gfx += 210;
				titleJSON.gfy += 40;
			case 'FUN':
				titleJSON.gfx += 210;
				titleJSON.gfy += 40;
			case 'RIVER':
				titleJSON.gfx += 100;
				titleJSON.gfy += 20;
			case 'SHUBS':
				titleJSON.gfx += 160;
				titleJSON.gfy -= 10;
			case 'BBPANZU':
				titleJSON.gfx += 45;
				titleJSON.gfy += 100;
		}
		#end

		if(!initialized && FlxG.save.data != null && FlxG.save.data.fullscreen)
		{
			FlxG.fullscreen = FlxG.save.data.fullscreen;
			//trace('LOADED FULLSCREEN SETTING!!');
		}

		if (FlxG.save.data.weekCompleted != null)
		{
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

		FlxG.mouse.visible = false;
		#if FREEPLAY
		MusicBeatState.switchState(new FreeplayState());
		#elseif CHARTING
		MusicBeatState.switchState(new ChartingState());
		#else
		if(FlxG.save.data.flashing == null && !FlashingState.leftState) {
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new FlashingState());
		} else {
			#if desktop
			if (!DiscordClient.isInitialized)
			{
				DiscordClient.initialize();
				Application.current.onExit.add (function (exitCode) {
					DiscordClient.shutdown();
				});
			}
			#end

			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				startIntro();
			});
		}
		#end
	}
var redGradient:FlxSprite;
	var logoBl:FlxSprite;
	var gfDance:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:FlxSprite;
	var swagShader:ColorSwap = null;

	function startIntro()
	{
		if (!initialized)
		{
			/*var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
			diamond.persist = true;
			diamond.destroyOnNoUse = false;
			FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 1, new FlxPoint(0, -1), {asset: diamond, width: 32, height: 32},
				new FlxRect(-300, -300, FlxG.width * 1.8, FlxG.height * 1.8));
			FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.7, new FlxPoint(0, 1),
				{asset: diamond, width: 32, height: 32}, new FlxRect(-300, -300, FlxG.width * 1.8, FlxG.height * 1.8));
				
			transIn = FlxTransitionableState.defaultTransIn;
			transOut = FlxTransitionableState.defaultTransOut;*/

			// HAD TO MODIFY SOME BACKEND SHIT
			// IF THIS PR IS HERE IF ITS ACCEPTED UR GOOD TO GO
			// https://github.com/HaxeFlixel/flixel-addons/pull/348

			// var music:FlxSound = new FlxSound();
			// music.loadStream(Paths.music('freakyMenu'));
			// FlxG.sound.list.add(music);
			// music.play();

			if(FlxG.sound.music == null) {
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			}
		}

		Conductor.changeBPM(titleJSON.bpm);
		persistentUpdate = true;
		

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('titleBG'));
		// bg.antialiasing = ClientPrefs.globalAntialiasing;
		// bg.setGraphicSize(Std.int(bg.width * 0.6));
		// bg.updateHitbox();
		add(bg);

		//logoBl = new FlxSprite(50, 120);
		//logoBl.frames = Paths.getSparrowAtlas('logoBumpin');
		//logoBl.antialiasing = ClientPrefs.globalAntialiasing;
		////logoBl.screenCenter(X);
		//logoBl.animation.addByPrefix('bump', 'logo bumpin', 24);
		//logoBl.animation.play('bump');
		//logoBl.updateHitbox();
		// logoBl.screenCenter();
		// logoBl.color = FlxColor.BLACK;
		
		var logoBl:FlxSprite = new FlxSprite().loadGraphic(Paths.image('titlelogonew'));
		add(logoBl);

		swagShader = new ColorSwap();
		gfDance = new FlxSprite(titleJSON.gfx, titleJSON.gfy);

		var easterEgg:String = FlxG.save.data.psychDevsEasterEgg;
		if(easterEgg == null) easterEgg = ''; //html5 fix

		switch(easterEgg.toUpperCase())
		{
			#if TITLE_SCREEN_EASTER_EGG
			case 'ROCKET':
				logoBl.alpha = 0;
				remove(bg);
				var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('bgs2/5'));
		add(bg);
		case 'BUCKET':
				logoBl.alpha = 0;
				remove(bg);
				var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('bgs2/10'));
		add(bg);
		//bg.frames = Paths.getSparrowAtlas('ROCKET');
	case 'CARROT':
		logoBl.alpha = 0;
		remove(bg);
				var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('bgs2/2'));
		add(bg);
		//bg.frames = Paths.getSparrowAtlas('CARROT');
	case 'MAKESHIP':
		logoBl.alpha = 0;
		remove(bg);
				var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('bgs2/4'));
		add(bg);
			//bg.frames = Paths.getSparrowAtlas('MAKESHIP');
	case 'APLAPLAC':
		logoBl.alpha = 0;
		remove(bg);
				var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('bgs2/1'));
		add(bg);
			//bg.frames = Paths.getSparrowAtlas('APLAPLAC');
	case 'JUSTICE':
		logoBl.alpha = 0;
		remove(bg);
				var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('bgs2/3'));
		add(bg);
			//bg.frames = Paths.getSparrowAtlas('JUSTICE');
	case 'VINNY':
		logoBl.alpha = 0;
		remove(bg);
				var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('bgs2/6'));
		add(bg);
		
		case 'HEARTACHES':
		logoBl.alpha = 0;
		remove(bg);
				var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('bgs2/7'));
		add(bg);
			//bg.frames = Paths.getSparrowAtlas('SPIN');
			
			case 'CLASSIC':
		logoBl.alpha = 1;
		remove(bg);
				var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('bgs2/8'));
		add(bg);
		
		case 'FUN':
		logoBl.alpha = 0;
		remove(bg);
				var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('bgs2/9'));
		add(bg);
		
			case 'RIVER':
				gfDance.frames = Paths.getSparrowAtlas('RiverBump');
				gfDance.animation.addByIndices('danceLeft', 'River Title Bump', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
				gfDance.animation.addByIndices('danceRight', 'River Title Bump', [29, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
			case 'SHUBS':
				gfDance.frames = Paths.getSparrowAtlas('ShubBump');
				gfDance.animation.addByPrefix('danceLeft', 'Shub Title Bump', 24, false);
				gfDance.animation.addByPrefix('danceRight', 'Shub Title Bump', 24, false);
			case 'BBPANZU':
				gfDance.frames = Paths.getSparrowAtlas('BBBump');
				gfDance.animation.addByIndices('danceLeft', 'BB Title Bump', [14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27], "", 24, false);
				gfDance.animation.addByIndices('danceRight', 'BB Title Bump', [27, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13], "", 24, false);
			#end

			default:
			//EDIT THIS ONE IF YOU'RE MAKING A SOURCE CODE MOD!!!!
			//EDIT THIS ONE IF YOU'RE MAKING A SOURCE CODE MOD!!!!
			//EDIT THIS ONE IF YOU'RE MAKING A SOURCE CODE MOD!!!!
			//bg.frames = Paths.getSparrowAtlas('titleBG');
			logoBl.alpha = 1;
				gfDance.frames = Paths.getSparrowAtlas('gfDanceTitle');
				gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
				gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		}
		gfDance.antialiasing = ClientPrefs.globalAntialiasing;
		
		//add(gfDance);
		//bg.shader = swagShader2.shader;
		//gfDance.shader = swagShader.shader;
		add(logoBl);
		logoBl.shader = swagShader.shader;

		titleText = new FlxSprite(titleJSON.startx, titleJSON.starty);
		#if (desktop && MODS_ALLOWED)
		var path = "mods/" + Paths.currentModDirectory + "/images/titleEnter.png";
		//trace(path, FileSystem.exists(path));
		if (!FileSystem.exists(path)){
			path = "mods/images/titleEnter.png";
		}
		//trace(path, FileSystem.exists(path));
		if (!FileSystem.exists(path)){
			path = "assets/images/titleEnter.png";
		}
		//trace(path, FileSystem.exists(path));
		titleText.frames = FlxAtlasFrames.fromSparrow(BitmapData.fromFile(path),File.getContent(StringTools.replace(path,".png",".xml")));
		#else
		
		titleText.frames = Paths.getSparrowAtlas('titleEnter');
		#end
		titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
		titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		titleText.antialiasing = ClientPrefs.globalAntialiasing;
		titleText.animation.play('idle');
		titleText.updateHitbox();
		titleText.screenCenter(X);
		add(titleText);

		var logo:FlxSprite = new FlxSprite().loadGraphic(Paths.image('logo'));
		logo.screenCenter();
		logo.antialiasing = ClientPrefs.globalAntialiasing;
		// add(logo);

		// FlxTween.tween(logoBl, {y: logoBl.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG});
		// FlxTween.tween(logo, {y: logoBl.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG, startDelay: 0.1});
		
		

		credGroup = new FlxGroup();
		add(credGroup);
		textGroup = new FlxGroup();
		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		credGroup.add(blackScreen);
			var redGradient:FlxSprite = new FlxSprite().loadGraphic(Paths.image('titlegradient'));
		//blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		
		if(!closedState) {
		FlxTween.tween(redGradient, {alpha: 1}, 10, {ease: FlxEase.linear});	
		}
		credGroup.add(redGradient);
		redGradient.alpha = 0;
		
		credTextShit = new Alphabet(0, 0, "", true);
		credTextShit.screenCenter();

		// credTextShit.alignment = CENTER;

		credTextShit.visible = false;

		ngSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('newgrounds_logo'));
		add(ngSpr);
		ngSpr.visible = false;
		ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.antialiasing = ClientPrefs.globalAntialiasing;

		FlxTween.tween(credTextShit, {y: credTextShit.y + 20}, 2.9, {ease: FlxEase.quadInOut, type: PINGPONG});

		if (initialized)
			skipIntro();
		else
			initialized = true;

		// credGroup.add(credTextShit);
	}

	function getIntroTextShit():Array<Array<String>>
	{
		var fullText:String = Assets.getText(Paths.txt('introText'));

		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
		{
			swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	var transitioning:Bool = false;
	private static var playJingle:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
		// FlxG.watch.addQuick('amp', FlxG.sound.music.amplitude);

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				pressedEnter = true;
			}
		}
		#end

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;

			#if switch
			if (gamepad.justPressed.B)
				pressedEnter = true;
			#end
		}
		
		//SOUND FOR TYPING
		
		if (FlxG.keys.justPressed.A || FlxG.keys.justPressed.B || FlxG.keys.justPressed.C || FlxG.keys.justPressed.D || FlxG.keys.justPressed.E || FlxG.keys.justPressed.F || FlxG.keys.justPressed.G || FlxG.keys.justPressed.H || FlxG.keys.justPressed.I || FlxG.keys.justPressed.J || FlxG.keys.justPressed.K || FlxG.keys.justPressed.L || FlxG.keys.justPressed.M || FlxG.keys.justPressed.N || FlxG.keys.justPressed.O || FlxG.keys.justPressed.P || FlxG.keys.justPressed.Q || FlxG.keys.justPressed.R || FlxG.keys.justPressed.S || FlxG.keys.justPressed.T || FlxG.keys.justPressed.U || FlxG.keys.justPressed.V || FlxG.keys.justPressed.W || FlxG.keys.justPressed.X || FlxG.keys.justPressed.Y || FlxG.keys.justPressed.Z)
    {
		 if (transitioning == false){
	  typeSound = FlxG.sound.load(Paths.sound('typesfx'), 1);
	  typeSound.play();
	   }
		else{		
	   typeSound = FlxG.sound.load(Paths.sound('typesfx'), 0);
	 
	   
		}
    }

		// EASTER EGG

		if (initialized && !transitioning && skippedIntro)
		{
			if(pressedEnter)
			{
				if(titleText != null) titleText.animation.play('press');

				FlxG.camera.flash(FlxColor.RED, 0.5);
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
				FlxG.sound.music.stop();

				transitioning = true;
				// FlxG.sound.music.stop();

				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					#if desktop
						MusicBeatState.switchState(new MainMenuState());
						FlxG.sound.playMusic(Paths.music('mainMenu'));
					#else
						MusicBeatState.switchState(new ForOnlinePlayers());
					#end
					closedState = true;
				});
				// FlxG.sound.play(Paths.music('titleShoot'), 0.7);
			}
			#if TITLE_SCREEN_EASTER_EGG
			else if (FlxG.keys.firstJustPressed() != FlxKey.NONE)
			{
				var keyPressed:FlxKey = FlxG.keys.firstJustPressed();
				var keyName:String = Std.string(keyPressed);
				if(allowedKeys.contains(keyName)) {
					easterEggKeysBuffer += keyName;
					if(easterEggKeysBuffer.length >= 32) easterEggKeysBuffer = easterEggKeysBuffer.substring(1);
					//trace('Test! Allowed Key pressed!!! Buffer: ' + easterEggKeysBuffer);

					for (wordRaw in easterEggKeys)
					{
						var word:String = wordRaw.toUpperCase(); //just for being sure you're doing it right
						if (easterEggKeysBuffer.contains(word))
						{
							//trace('YOOO! ' + word);
							if (FlxG.save.data.psychDevsEasterEgg == word)
								FlxG.save.data.psychDevsEasterEgg = '';
							else
								FlxG.save.data.psychDevsEasterEgg = word;
							FlxG.save.flush();

							FlxG.sound.play(Paths.sound('ToggleJingle'));

							var black:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
							black.alpha = 0;
							add(black);

							FlxTween.tween(black, {alpha: 1}, 1, {onComplete:
								function(twn:FlxTween) {
									FlxTransitionableState.skipNextTransIn = true;
									FlxTransitionableState.skipNextTransOut = true;
									new FlxTimer().start(2, function(tmr:FlxTimer){
									MusicBeatState.switchState(new TitleState()); 
									
									});
								}
							});
							FlxG.sound.music.fadeOut();
							FlxG.sound.play(Paths.sound('typesuccess'));
							closedState = true;
							transitioning = true;
							playJingle = true;
							easterEggKeysBuffer = '';
							break;
						}
					}
				}
			}
			#end
		}

		if (initialized && pressedEnter && !skippedIntro)
		{
			skipIntro();
		}

		if(swagShader != null)
		{
			if(controls.UI_LEFT) swagShader.hue -= elapsed * 0.1;
			if(controls.UI_RIGHT) swagShader.hue += elapsed * 0.1;
		}
		

		super.update(elapsed);
	}
	

	function createCoolText(textArray:Array<String>, ?offset:Float = 0)
	{
		for (i in 0...textArray.length)
		{

			var money:Alphabet = new Alphabet(0, 0, textArray[i], true, false);
			money.screenCenter(X);
			money.y += (i * 60) + 200 + offset;
			if(credGroup != null && textGroup != null) {
				credGroup.add(money);
				textGroup.add(money);
			}
		}
	}

	function addMoreText(text:String, ?offset:Float = 0)
	{
		if(textGroup != null && credGroup != null) {
			var coolText:Alphabet = new Alphabet(0, 0, text, true, false);
			coolText.screenCenter(X);
			coolText.y += (textGroup.length * 60) + 200 + offset;
			credGroup.add(coolText);
			textGroup.add(coolText);
		}
	}

	function deleteCoolText()
	{
		while (textGroup.members.length > 0)
		{
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
	}

	private var sickBeats:Int = 0; //Basically curBeat but won't be skipped if you hold the tab or resize the screen
	public static var closedState:Bool = false;
	override function beatHit()
	{
		super.beatHit();

		if(logoBl != null) 
			logoBl.animation.play('bump', true);

		if(gfDance != null) {
			danceLeft = !danceLeft;
			if (danceLeft)
				gfDance.animation.play('danceRight');
			else
				gfDance.animation.play('danceLeft');
		}

		if(!closedState) {
			sickBeats++;
			switch (sickBeats)
			{
				case 1:
					FlxG.sound.music.stop();
					FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
					FlxG.sound.music.fadeIn(4, 0, 0.7);
				case 2:
					#if PSYCH_WATERMARKS
					createCoolText(['Psych Engine by'], 15);
					#else
					createCoolText(["The Funkin' Files Team"]);
					#end
				// credTextShit.visible = true;
				case 4:
					#if PSYCH_WATERMARKS
					addMoreText('Shadow Mario', 15);
					addMoreText('RiverOaken', 15);
					addMoreText('shubs', 15);
					#else
					addMoreText('proudly presents');
					#end
				// credTextShit.text += '\npresent...';
				// credTextShit.addText();
				case 5:
					deleteCoolText();
				// credTextShit.visible = false;
				// credTextShit.text = 'In association \nwith';
				// credTextShit.screenCenter();
				case 6:
					#if PSYCH_WATERMARKS
					createCoolText(['Not associated', 'with'], -40);
					#else
					createCoolText(['Original series by'], -40);
					#end
				case 8:
					addMoreText('Martin Walls', -45);
					ngSpr.visible = false;
				// credTextShit.text += '\nNewgrounds';
				case 9:
					deleteCoolText();
					ngSpr.visible = false;
				// credTextShit.visible = false;

				// credTextShit.text = 'Shoutouts Tom Fulp';
				// credTextShit.screenCenter();
				case 10:
					createCoolText([curWacky[0]]);
				// credTextShit.visible = true;
				case 12:
					addMoreText(curWacky[1]);
				// credTextShit.text += '\nlmao';
				case 13:
					deleteCoolText();
				// credTextShit.visible = false;
				// credTextShit.text = "Friday";
				// credTextShit.screenCenter();
				case 14:
					addMoreText('The');
				// credTextShit.visible = true;
				case 15:
					addMoreText("Funkin'");
				// credTextShit.text += '\nNight';
				case 16:
					addMoreText('Files'); // credTextShit.text += '\nFunkin';

				case 17:
					skipIntro();

			}
		}
	}

	var skippedIntro:Bool = false;
	var increaseVolume:Bool = false;
	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			if (playJingle) //Ignore deez
			{
				var easteregg:String = FlxG.save.data.psychDevsEasterEgg;
				if (easteregg == null) easteregg = '';
				easteregg = easteregg.toUpperCase();

				var sound:FlxSound = null;
				switch(easteregg)
				{
					case 'RIVER':
						sound = FlxG.sound.play(Paths.sound('JingleRiver'));
					case 'SHUBS':
						sound = FlxG.sound.play(Paths.sound('JingleShubs'));
					case 'ROCKET':
						var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('bgs2/r'));
							bg.setGraphicSize(FlxG.width, FlxG.height);
			bg.screenCenter();
							add(bg);
						FlxG.sound.play(Paths.sound('JingleRocket'));
					case 'BUCKET':
						//FlxG.sound.play(Paths.sound('JingleRoots'));
					case 'CARROT':
						FlxG.sound.play(Paths.sound('JingleRoots'));
					case 'MAKESHIP':
						FlxG.sound.play(Paths.sound('JinglePlush'));
					case 'APLAPLAC':
						//FlxG.sound.play(Paths.sound('JinglePlush'));
					case 'JUSTICE':
						//FlxG.sound.play(Paths.sound('JinglePlush'));
					case 'VINNY':
						//FlxG.sound.play(Paths.sound('JinglePlush'));
					case 'HEARTACHES':
						//FlxG.sound.play(Paths.sound('JinglePlush'));
					case 'CLASSIC':
						//FlxG.sound.play(Paths.sound('JinglePlush'));
					case 'FUN':
						//FlxG.sound.play(Paths.sound('JinglePlush'));
					case 'BBPANZU':
						sound = FlxG.sound.play(Paths.sound('JingleBB'));
					
					default: //Go back to normal ugly ass boring GF
						remove(ngSpr);
						remove(credGroup);
						FlxG.camera.flash(FlxColor.BLACK, 0.5);
						skippedIntro = true;
						playJingle = false;
						
						FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						return;
				}

				transitioning = true;
				if(easteregg == 'ROCKET')
				{
					PlayState.SONG = Song.loadFromJson('remember', 'remember');
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = 2;
			PlayState.storyWeek = 1;
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			new FlxTimer().start(7, function(tmr:FlxTimer)
			{
				LoadingState.loadAndSwitchState(new PlayState());
							closedState = true;
							transitioning = true;
				
			});
				}
				else if(easteregg == 'CARROT')
				{
					PlayState.SONG = Song.loadFromJson('roots', 'roots');
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = 2;
			PlayState.storyWeek = 1;
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				LoadingState.loadAndSwitchState(new PlayState());
							closedState = true;
							transitioning = true;
				
			});
				}
				else if(easteregg == 'MAKESHIP') 
				{
					PlayState.SONG = Song.loadFromJson('marketable-plushie', 'marketable-plushie');
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = 2;
			PlayState.storyWeek = 1;
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				LoadingState.loadAndSwitchState(new PlayState());
							closedState = true;
							transitioning = true;
				
			});
				}
				else if(easteregg == 'APLAPLAC') 
				{
					PlayState.SONG = Song.loadFromJson('minutos', 'minutos');
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = 2;
			PlayState.storyWeek = 1;
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				LoadingState.loadAndSwitchState(new PlayState());
							closedState = true;
							transitioning = true;
				
			});
				}
				else if(easteregg == 'JUSTICE') 
				{
					PlayState.SONG = Song.loadFromJson('ursidae', 'ursidae');
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = 2;
			PlayState.storyWeek = 1;
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				LoadingState.loadAndSwitchState(new PlayState());
							closedState = true;
							transitioning = true;
				
			});
				}
				else if(easteregg == 'HEARTACHES') 
				{
					PlayState.SONG = Song.loadFromJson('lucky-you', 'lucky-you');
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = 2;
			PlayState.storyWeek = 1;
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				LoadingState.loadAndSwitchState(new PlayState());
							closedState = true;
							transitioning = true;
				
			});
				}
				else if(easteregg == 'CLASSIC') 
				{
					PlayState.SONG = Song.loadFromJson('repurpose', 'repurpose');
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = 2;
			PlayState.storyWeek = 1;
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				LoadingState.loadAndSwitchState(new PlayState());
							closedState = true;
							transitioning = true;
				
			});
				}
			else if(easteregg == 'FUN') 
				{
					PlayState.SONG = Song.loadFromJson('rendezvous', 'rendezvous');
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = 2;
			PlayState.storyWeek = 1;
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				LoadingState.loadAndSwitchState(new PlayState());
							closedState = true;
							transitioning = true;
				
			});
			
				}
				else if(easteregg == 'BUCKET') 
				{
					PlayState.SONG = Song.loadFromJson('grain', 'grain');
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = 2;
			PlayState.storyWeek = 1;
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				LoadingState.loadAndSwitchState(new PlayState());
							closedState = true;
							transitioning = true;
				
			});
			
				}
				else if(easteregg == 'VINNY') 
				{
					PlayState.SONG = Song.loadFromJson('spin', 'spin');
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = 2;
			PlayState.storyWeek = 1;
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				LoadingState.loadAndSwitchState(new PlayState());
							closedState = true;
							transitioning = true;
				
			});
				}
				else
				{
					remove(ngSpr);
					remove(credGroup);
					FlxG.camera.flash(FlxColor.RED, 0.5);
					sound.onComplete = function() {
						FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						transitioning = false;
					};
				}
				playJingle = false;
			}
			else //Default! Edit this one!!
			{
				remove(ngSpr);
				remove(credGroup);
				FlxG.camera.flash(FlxColor.BLACK, 0.5);

				var easteregg:String = FlxG.save.data.psychDevsEasterEgg;
				if (easteregg == null) easteregg = '';
				easteregg = easteregg.toUpperCase();
				#if TITLE_SCREEN_EASTER_EGG
				if(easteregg == 'ROCKET')
				{
					//FlxG.sound.music.fadeOut();
				}
				#end
			}
			
			
			
			skippedIntro = true;
		}
	}
}