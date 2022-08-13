package options;

#if desktop
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxSubState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;

using StringTools;

class ModExtrasSubstate extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Extra Settings';
		rpcTitle = 'Extra Settings'; //for Discord Rich Presence
		
		//I'd suggest using "Downscroll" as an example for making your own option since it is the simplest here
		var option:Option = new Option('VHS', //Name
			'If checked, a VHS filter will appear. (Songs only)', //Description
			'shaders', //Save data variable name
			'bool', //Variable type
			true); //Default value
		addOption(option);
		
		var option:Option = new Option('4:3 Aspect Ratio', //Name
			'If checked, the aspect ratio will change to 4:3. (Songs only)', //Description
			'squareRatio', //Save data variable name
			'bool', //Variable type
			true); //Default value
		addOption(option);
		
			var option:Option = new Option('Captions', //Name
			'If checked, captions will appear when characters are speaking. (Songs only)', //Description
			'captions', //Save data variable name
			'bool', //Variable type
			true); //Default value
		addOption(option);
		
		var option:Option = new Option('Icon Bounce:',
			'Change how your icons bounce.',
			'iconBounce',
			'string',
			'New Bounce',
			['New Bounce', 'Old Bounce']);
		addOption(option);

		super();
	}
}