function onEvent(name,value1,value2)
	if name == 'No HUD' then
	
		if value1 == '1' then
						doTweenAlpha('GUItween', 'camHUD', 0, 0.01, 'linear');
		end
	end
	end	