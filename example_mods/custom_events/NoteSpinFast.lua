function onEvent(name)
	if name ~= 'NoteSpinFast' then
		return
	end
	
	local sowy = getProperty('strumLineNotes.length')-1
	for i = 0, sowy do
		setPropertyFromGroup('strumLineNotes', i, 'angle', 0)
	end
	for i = 0, sowy do
		noteTweenAngle("ang"..i, i, 360, 0.25, "expoInOut")
	end
end