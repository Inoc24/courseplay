-- handles "mode1" : waiting at start until tippers full - driving course and unloading on trigger
function courseplay:handle_mode1(vehicle, allowedToDrive)
	-- done tipping
	if vehicle.cp.currentTipTrigger and vehicle.cp.tipperFillLevel == 0 then
		courseplay:resetTipTrigger(vehicle, true);
	end

	-- tippers are not full
	if vehicle.cp.isLoaded ~= true and ((vehicle.recordnumber == 2 and vehicle.cp.tipperFillLevel < vehicle.cp.tipperCapacity and vehicle.cp.isUnloaded == false) or vehicle.cp.trailerFillDistance) then
		allowedToDrive = courseplay:load_tippers(vehicle, allowedToDrive);
		courseplay:setInfoText(vehicle, string.format(courseplay:loc("COURSEPLAY_LOADING_AMOUNT"), vehicle.cp.tipperFillLevel, vehicle.cp.tipperCapacity));
	end

	-- damn, I missed the trigger!
	if vehicle.cp.currentTipTrigger ~= nil then
		local t = vehicle.cp.currentTipTrigger;
		local trigger_id = t.triggerId;

		if t.specialTriggerId ~= nil then
			trigger_id = t.specialTriggerId;
		end;
		if t.isPlaceableHeapTrigger then
			trigger_id = t.rootNode;
		end;

		if trigger_id ~= nil then
			local trigger_x, trigger_y, trigger_z = getWorldTranslation(trigger_id)
			local ctx, cty, ctz = getWorldTranslation(vehicle.cp.DirectionNode);
			local distance_to_trigger = courseplay:distance(ctx, ctz, trigger_x, trigger_z);

			-- Start reversing value is to check if we have started to reverse
			-- This is used in case we already registered a tipTrigger but changed the direction and might not be in that tipTrigger when unloading. (Bug Fix)
			local startReversing = vehicle.Waypoints[vehicle.recordnumber].rev and not vehicle.Waypoints[vehicle.cp.lastRecordnumber].rev;
			if startReversing then
				courseplay:debug(string.format("%s: Is starting to reverse. Tip trigger is reset.", nameNum(vehicle)), 13);
			end;

			local extraLength = 5;
			if t.bunkerSilo ~= nil and t.bunkerSilo.movingPlanes ~= nil and vehicle.cp.handleAsOneSilo ~= true then
				-- We are a bunkerSilo, so we need to add more extraLength to the totalLength.
				extraLength = 55;
			end;

			if distance_to_trigger > (vehicle.cp.totalLength + extraLength) or startReversing then
				courseplay:resetTipTrigger(vehicle);
				courseplay:debug(string.format("%s: distance to currentTipTrigger = %d (> %d or start reversing) --> currentTipTrigger = nil", nameNum(vehicle), distance_to_trigger, (vehicle.cp.totalLength + 5)), 1);
			end
		else
			courseplay:resetTipTrigger(vehicle);
		end;
	end;

	-- tipper is not empty and tractor reaches TipTrigger
	if vehicle.cp.tipperFillLevel > 0 and vehicle.cp.currentTipTrigger ~= nil and vehicle.recordnumber > 3 then
		allowedToDrive = courseplay:unload_tippers(vehicle, allowedToDrive);
		courseplay:setInfoText(vehicle, courseplay:loc("COURSEPLAY_TIPTRIGGER_REACHED"));
	end;

	return allowedToDrive;
end;
