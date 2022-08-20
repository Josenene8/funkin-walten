package;

#if desktop
import Discord.DiscordClient;
#end
import editors.ChartingState;
import Song.SwagSong;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import lime.utils.Assets;
import flixel.system.FlxSound;
import openfl.utils.Assets as OpenFlAssets;
#if MODS_ALLOWED
import sys.FileSystem;
#end

using StringTools;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	private static var curSelected:Int = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = '';

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var comboText:FlxText;
	var diffText:FlxText;
	var charText:FlxText;
	var charIcon:FlxSprite;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var bg1:FlxSprite;
	var bg2:FlxSprite;
	var bg3:FlxSprite;
	var bg4:FlxSprite;
	var bg5:FlxSprite;
	var bg6:FlxSprite;
	var bg7:FlxSprite;
	var bg8:FlxSprite;
	var bg9:FlxSprite;
	var bg10:FlxSprite;
	var bg11:FlxSprite;
	var bg12:FlxSprite;
	var bg13:FlxSprite;
	var bg14:FlxSprite;
	var bg15:FlxSprite;
	var bg16:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;
	
	public static var SONG:SwagSong = null;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		for (i in 0...WeekData.weeksList.length) {
			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];
			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		WeekData.loadTheFirstEnabledMod();

		/*		//KIND OF BROKEN NOW AND ALSO PRETTY USELESS//

		var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));
		for (i in 0...initSonglist.length)
		{
			if(initSonglist[i] != null && initSonglist[i].length > 0) {
				var songArray:Array<String> = initSonglist[i].split(":");
				addSong(songArray[0], 0, songArray[1], Std.parseInt(songArray[2]));
			}
		}*/

		bg = new FlxSprite().loadGraphic(Paths.image('songbgs/Dark'));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);
		bg.screenCenter();
		
		bg1 = new FlxSprite().loadGraphic(Paths.image('songbgs/Quantum'));
		bg1.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg1);
		bg1.screenCenter();
		bg1.alpha = 0;
		
		bg2 = new FlxSprite().loadGraphic(Paths.image('songbgs/Protocol'));
		bg2.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg2);
		bg2.screenCenter();
		bg2.alpha = 0;
		
		bg3 = new FlxSprite().loadGraphic(Paths.image('songbgs/Sleepover'));
		bg3.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg3);
		bg3.screenCenter();
		bg3.alpha = 0;

		
		bg4 = new FlxSprite().loadGraphic(Paths.image('songbgs/Caution'));
		bg4.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg4);
		bg4.screenCenter();
		bg4.alpha = 0;

		
		bg5 = new FlxSprite().loadGraphic(Paths.image('songbgs/Relocation'));
		bg5.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg5);
		bg5.screenCenter();
		bg5.alpha = 0;

		
		bg6 = new FlxSprite().loadGraphic(Paths.image('songbgs/Starving'));
		bg6.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg6);
		bg6.screenCenter();
		bg6.alpha = 0;

		
		bg7 = new FlxSprite().loadGraphic(Paths.image('songbgs/Mangled'));
		bg7.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg7);
		bg7.screenCenter();
		bg7.alpha = 0;

		
		bg8 = new FlxSprite().loadGraphic(Paths.image('songbgs/Blunder'));
		bg8.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg8);
		bg8.screenCenter();
		bg8.alpha = 0;

		
		bg9 = new FlxSprite().loadGraphic(Paths.image('songbgs/Stranger'));
		bg9.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg9);
		bg9.screenCenter();
		bg9.alpha = 0;

		
		bg10 = new FlxSprite().loadGraphic(Paths.image('songbgs/Boogeyman'));
		bg10.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg10);
		bg10.screenCenter();
		bg10.alpha = 0;

		
		bg11 = new FlxSprite().loadGraphic(Paths.image('songbgs/Lies'));
		bg11.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg11);
		bg11.screenCenter();
		bg11.alpha = 0;

		
		bg12 = new FlxSprite().loadGraphic(Paths.image('songbgs/Ripple'));
		bg12.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg12);
		bg12.screenCenter();
		bg12.alpha = 0;

		
		bg13 = new FlxSprite().loadGraphic(Paths.image('songbgs/Mortality'));
		bg13.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg13);
		bg13.screenCenter();
		bg13.alpha = 0;

		
		bg14 = new FlxSprite().loadGraphic(Paths.image('songbgs/Sleepover_Remix'));
		bg14.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg14);
		bg14.screenCenter();
		bg14.alpha = 0;

		
		bg15 = new FlxSprite().loadGraphic(Paths.image('songbgs/Caution'));
		bg15.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg15);
		bg15.screenCenter();
		bg15.alpha = 0;



		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false);
			songText.isMenuItemCenter = true;
			songText.targetY = i;
			grpSongs.add(songText);

			if (songText.width > 980)
			{
				var textScale:Float = 980 / songText.width;
				songText.scale.x = textScale;
				for (letter in songText.lettersArray)
				{
					letter.x *= textScale;
					letter.offset.x *= textScale;
				}
				//songText.updateHitbox();
				//trace(songs[i].songName + ' new scale: ' + textScale);
			}

			Paths.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}
		WeekData.setDirectoryFromWeek();

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);
		
		comboText = new FlxText(diffText.x + 100, diffText.y, 0, "", 24);
		comboText.font = diffText.font;
		add(comboText);
		
		charText = new FlxText(comboText.x - 50, comboText.y + 65, 0, "TAB ", 24);
		charText.font = comboText.font;
		//add(charText);
		
		charIcon = new HealthIcon('charselecticon', true);
		charIcon.setPosition(charText.x - 100, comboText.y + 10);
		charIcon.scale.set(0.5, 0.5);
		charIcon.updateHitbox();
		add(charIcon);
		
		add(scoreText);

		if(curSelected >= songs.length) curSelected = 0;
		//bg.color = songs[curSelected].color;
		//intendedColor = bg.color;

		if(lastDifficultyName == '')
		{
			lastDifficultyName = CoolUtil.defaultDifficulty;
		}
		curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName)));
		
		changeSelection();
		changeDiff();
		
 
		
		var swag:Alphabet = new Alphabet(1, 0, "swag");

		// JUST DOIN THIS SHIT FOR TESTING!!!
		/* 
			var md:String = Markdown.markdownToHtml(Assets.getText('CHANGELOG.md'));

			var texFel:TextField = new TextField();
			texFel.width = FlxG.width;
			texFel.height = FlxG.height;
			// texFel.
			texFel.htmlText = md;

			FlxG.stage.addChild(texFel);

			// scoreText.textField.htmlText = md;

			trace(md);
		 */

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		#if PRELOAD_ALL
		var leText:String = "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 16;
		#else
		var leText:String = "Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 18;
		#end
		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, leText, size);
		text.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, CENTER);
		text.scrollFactor.set();
		add(text);
		#if android
addVirtualPad(LEFT_FULL, A_B_C);
#end

		super.create();
	}

	override function closeSubState() {
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	/*public function addWeek(songs:Array<String>, weekNum:Int, weekColor:Int, ?songCharacters:Array<String>)
	{
		if (songCharacters == null)
			songCharacters = ['bf'];

		var num:Int = 0;
		for (song in songs)
		{
			addSong(song, weekNum, songCharacters[num]);
			this.songs[this.songs.length-1].color = weekColor;

			if (songCharacters.length != 1)
				num++;
		}
	}*/
	
	var selectedSomethin:Bool = false;

	var instPlaying:Int = -1;
	private static var vocals:FlxSound = null;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 12, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, CoolUtil.boundTo(elapsed * 6, 0, 1));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(Highscore.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) { //No decimals, add an empty space
			ratingSplit.push('');
		}
		
		while(ratingSplit[1].length < 2) { //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}

		scoreText.text = 'HIGH SCORE: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';
		positionHighscore();

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;
		var space = FlxG.keys.justPressed.SPACE;
		var ctrl = FlxG.keys.justPressed.CONTROL;

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if(songs.length > 1)
		{
			if (upP)
			{
				changeSelection(-shiftMult);
				holdTime = 0;
			}
			if (downP)
			{
				changeSelection(shiftMult);
				holdTime = 0;
			}

			if(controls.UI_DOWN || controls.UI_UP)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
				{
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					changeDiff();
				}
			}
		}
		
		

		if (controls.UI_LEFT_P)
			changeDiff(-1);
		else if (controls.UI_RIGHT_P)
			changeDiff(1);
		else if (upP || downP) changeDiff();

		if (controls.BACK)
		{
			persistentUpdate = false;
			if(colorTween != null) {
				colorTween.cancel();
			}
			FlxG.sound.play(Paths.sound('cancelMenu'));
			destroyFreeplayVocals();
			FlxG.sound.music.stop();
			MusicBeatState.switchState(new MainMenuState());
			FlxG.sound.playMusic(Paths.music('mainMenu'), 0);
		}
		
		//if (FlxG.keys.justPressed.TAB)
			//{
				//selectedSomethin = true;
				//destroyFreeplayVocals();
				//FlxG.sound.music.stop();
				//MusicBeatState.switchState(new FreeplayPicoState());
			//}

		if(ctrl)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}
		else if(space)
		{
			if(instPlaying != curSelected)
			{
				#if PRELOAD_ALL
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				Paths.currentModDirectory = songs[curSelected].folder;
				var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
				PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
				if (PlayState.SONG.needsVoices)
					vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
				else
					vocals = new FlxSound();

				FlxG.sound.list.add(vocals);
				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.7);
				vocals.play();
				vocals.persist = true;
				vocals.looped = true;
				vocals.volume = 0.7;
				instPlaying = curSelected;
				#end
			}
		}

		else if (accepted)
		{
			persistentUpdate = false;
			var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
			var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
			/*#if MODS_ALLOWED
			if(!sys.FileSystem.exists(Paths.modsJson(songLowercase + '/' + poop)) && !sys.FileSystem.exists(Paths.json(songLowercase + '/' + poop))) {
			#else
			if(!OpenFlAssets.exists(Paths.json(songLowercase + '/' + poop))) {
			#end
				poop = songLowercase;
				curDifficulty = 1;
				trace('Couldnt find file');
			}*/
			trace(poop);

			PlayState.SONG = Song.loadFromJson(poop, songLowercase);
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = curDifficulty;

			trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
			if(colorTween != null) {
				colorTween.cancel();
			}
			
			if (FlxG.keys.pressed.SHIFT){
				LoadingState.loadAndSwitchState(new ChartingState());
			}
			else if (curSelected == 1 || curSelected == 2  ||curSelected == 3 ){
				LoadingState.loadAndSwitchState(new CharSelectState()); }
			else{
				LoadingState.loadAndSwitchState(new PlayState());
			}
			

			FlxG.sound.music.volume = 0;
					
			destroyFreeplayVocals();
		}
		else if(controls.RESET)
		{
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		super.update(elapsed);
	}

	public static function destroyFreeplayVocals() {
		if(vocals != null) {
			vocals.stop();
			vocals.destroy();
		}
		vocals = null;
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		//if (curDifficulty < 0)
			//curDifficulty = CoolUtil.difficulties.length-1;
		//if (curDifficulty >= CoolUtil.difficulties.length)
			//curDifficulty = 0;
			
			if (curDifficulty > 2)
			curDifficulty = 0;
		if (curDifficulty < 0)
			curDifficulty = 2;
			
			// CHANGE THIS EVERY TIME A NEW SONG IS ADDED!!!
			if (curSelected == 13 && curDifficulty < 3)
			curDifficulty = 3;
			if (curSelected == 13 && curDifficulty > 3)
			curDifficulty = 3;
			if (curSelected == 14 && curDifficulty < 3)
			curDifficulty = 3;
			if (curSelected == 14 && curDifficulty > 3)
			curDifficulty = 3;// remixes
			
			
						

		lastDifficultyName = CoolUtil.difficulties[curDifficulty];

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		PlayState.storyDifficulty = curDifficulty;
		diffText.text = '< ' + CoolUtil.difficultyString() + ' >';
		positionHighscore();
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'));

		curSelected += change;
			
		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;
			
			switch(curSelected){
        case 0:
			FlxTween.tween(bg15, {alpha: 0}, 0.3, {ease: FlxEase.linear});	
			FlxTween.tween(bg1, {alpha: 1}, 0.3, {ease: FlxEase.linear});	
			FlxTween.tween(bg2, {alpha: 0}, 0.3, {ease: FlxEase.linear});
		charIcon.visible = false;
	case 1:
		FlxTween.tween(bg1, {alpha: 0}, 0.3, {ease: FlxEase.linear});	
			FlxTween.tween(bg2, {alpha: 1}, 0.3, {ease: FlxEase.linear});	
			FlxTween.tween(bg3, {alpha: 0}, 0.3, {ease: FlxEase.linear});
		charIcon.visible = true;
	case 2:
		FlxTween.tween(bg2, {alpha: 0}, 0.3, {ease: FlxEase.linear});	
			FlxTween.tween(bg3, {alpha: 1}, 0.3, {ease: FlxEase.linear});	
			FlxTween.tween(bg4, {alpha: 0}, 0.3, {ease: FlxEase.linear});
		charIcon.visible = true;
	case 3:
		FlxTween.tween(bg3, {alpha: 0}, 0.3, {ease: FlxEase.linear});	
			FlxTween.tween(bg4, {alpha: 1}, 0.3, {ease: FlxEase.linear});	
			FlxTween.tween(bg5, {alpha: 0}, 0.3, {ease: FlxEase.linear});
		charIcon.visible = true;
		 case 4:
			 FlxTween.tween(bg4, {alpha: 0}, 0.3, {ease: FlxEase.linear});	
			FlxTween.tween(bg5, {alpha: 1}, 0.3, {ease: FlxEase.linear});	
			FlxTween.tween(bg6, {alpha: 0}, 0.3, {ease: FlxEase.linear});
		charIcon.visible = false;
		 case 5:
			 FlxTween.tween(bg5, {alpha: 0}, 0.3, {ease: FlxEase.linear});	
			FlxTween.tween(bg6, {alpha: 1}, 0.3, {ease: FlxEase.linear});	
			FlxTween.tween(bg7, {alpha: 0}, 0.3, {ease: FlxEase.linear});
		charIcon.visible = false;
		 case 6:
			 FlxTween.tween(bg6, {alpha: 0}, 0.3, {ease: FlxEase.linear});	
			FlxTween.tween(bg7, {alpha: 1}, 0.3, {ease: FlxEase.linear});	
			FlxTween.tween(bg8, {alpha: 0}, 0.3, {ease: FlxEase.linear});
		charIcon.visible = false;
		 case 7:
			  FlxTween.tween(bg7, {alpha: 0}, 0.3, {ease: FlxEase.linear});	
			FlxTween.tween(bg8, {alpha: 1}, 0.3, {ease: FlxEase.linear});	
			FlxTween.tween(bg9, {alpha: 0}, 0.3, {ease: FlxEase.linear});
		charIcon.visible = false;
		 case 8:
			  FlxTween.tween(bg8, {alpha: 0}, 0.3, {ease: FlxEase.linear});	
			FlxTween.tween(bg9, {alpha: 1}, 0.3, {ease: FlxEase.linear});	
			FlxTween.tween(bg10, {alpha: 0}, 0.3, {ease: FlxEase.linear});
		charIcon.visible = false;
		 case 9:
			  FlxTween.tween(bg9, {alpha: 0}, 0.3, {ease: FlxEase.linear});	
			FlxTween.tween(bg10, {alpha: 1}, 0.3, {ease: FlxEase.linear});	
			FlxTween.tween(bg11, {alpha: 0}, 0.3, {ease: FlxEase.linear});
		charIcon.visible = false;
		 case 10:
			 FlxTween.tween(bg10, {alpha: 0}, 0.3, {ease: FlxEase.linear});	
			FlxTween.tween(bg11, {alpha: 1}, 0.3, {ease: FlxEase.linear});	
			FlxTween.tween(bg12, {alpha: 0}, 0.3, {ease: FlxEase.linear});
		charIcon.visible = false;
		 case 11:
			 	 FlxTween.tween(bg11, {alpha: 0}, 0.3, {ease: FlxEase.linear});	
			FlxTween.tween(bg12, {alpha: 1}, 0.3, {ease: FlxEase.linear});	
			FlxTween.tween(bg13, {alpha: 0}, 0.3, {ease: FlxEase.linear});
		charIcon.visible = false;
		 case 12:
			  FlxTween.tween(bg12, {alpha: 0}, 0.3, {ease: FlxEase.linear});	
			FlxTween.tween(bg13, {alpha: 1}, 0.3, {ease: FlxEase.linear});	
			FlxTween.tween(bg14, {alpha: 0}, 0.3, {ease: FlxEase.linear});
		charIcon.visible = false;
		 case 13:
			   FlxTween.tween(bg13, {alpha: 0}, 0.3, {ease: FlxEase.linear});	
			FlxTween.tween(bg14, {alpha: 1}, 0.3, {ease: FlxEase.linear});	
			FlxTween.tween(bg15, {alpha: 0}, 0.3, {ease: FlxEase.linear});
		charIcon.visible = false;
		 case 14:
			  FlxTween.tween(bg14, {alpha: 0}, 0.3, {ease: FlxEase.linear});	
			FlxTween.tween(bg15, {alpha: 1}, 0.3, {ease: FlxEase.linear});	
			FlxTween.tween(bg1, {alpha: 0}, 0.3, {ease: FlxEase.linear});
		charIcon.visible = false;
        }
			
		//var newColor:Int = songs[curSelected].color;
		//if(newColor != intendedColor) {
			//if(colorTween != null) {
				//colorTween.cancel();
			//}
			//intendedColor = newColor;
			//colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				//onComplete: function(twn:FlxTween) {
					//colorTween = null;
				//}
			//});
		//}

		// selector.y = (70 * curSelected) + 30;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
		
		Paths.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;

		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
		var diffStr:String = WeekData.getCurrentWeek().difficulties;
		if(diffStr != null) diffStr = diffStr.trim(); //Fuck you HTML5

		if(diffStr != null && diffStr.length > 0)
		{
			var diffs:Array<String> = diffStr.split(',');
			var i:Int = diffs.length - 1;
			while (i > 0)
			{
				if(diffs[i] != null)
				{
					diffs[i] = diffs[i].trim();
					if(diffs[i].length < 1) diffs.remove(diffs[i]);
				}
				--i;
			}

			if(diffs.length > 0 && diffs[0].length > 0)
			{
				CoolUtil.difficulties = diffs;
			}
		}
		
		if(CoolUtil.difficulties.contains(CoolUtil.defaultDifficulty))
		{
			curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty)));
		}
		else
		{
			curDifficulty = 0;
		}

		var newPos:Int = CoolUtil.difficulties.indexOf(lastDifficultyName);
		//trace('Pos of ' + lastDifficultyName + ' is ' + newPos);
		if(newPos > -1)
		{
			curDifficulty = newPos;
		}
	}

	private function positionHighscore() {
		scoreText.x = FlxG.width - scoreText.width - 6;

		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Paths.currentModDirectory;
		if(this.folder == null) this.folder = '';
	}
}
