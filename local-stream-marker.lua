-- Local Stream Marker v1.11

-- initialize functions with local scope, duh
-- OBS stuff
local obs 								= obslua
local script_settings					= nil

-- file stuff
local output_file_name 					= "obs-local-stream-marker.csv";
local output_file_name_custom			= "obs-local-stream-marker [date]";
local output_file_name_current			= "";
local output_file_extension				= "%.csv$";
local output_folder 					= "";
local output_path						= "";
local output_datetime_format			= "%Y-%m-%d";
local use_custom_filename				= false;
local reset_custom_filename				= true;
local show_log							= false;
local comments_enabled					= false;
local preset_file_extension				= ".markerpresets"

-- CSV stuff
local csv_headers 						= "Date Time, Stream Start, Stream Timestamp, Stream End Mark Timestamp, Recording Full Path, Recording Filename, Recording Timestamp, Recording End Mark Timestamp, Recording Timestamp on File, Recording End Mark Timestamp on File, Comment";
local output_format 					= "$current_time, $stream_start_time, $stream_timestamp, $stream_mark_end_timestamp, $recording_path, $recording_filename, $recording_timestamp, $recording_mark_end_timestamp, $recording_file_timestamp, $recording_file_mark_end_timestamp, $comment";
local recording_path					= "";
local recording_filename 				= "";

-- marker time stuff
local stream_timestamp 					= "n/a";
local stream_mark_end_timestamp			= "n/a";
local recording_timestamp 				= "n/a";
local recording_mark_end_timestamp		= "n/a";
local recording_file_timestamp 			= "n/a";
local recording_file_mark_end_timestamp = "n/a";
local recording_file_frame_count 		= 0
local recording_frame_count_on_split 	= 0
local stream_start_time 				= "n/a";

-- hotkey stuff
local marker_hotkey_id 					= obs.OBS_INVALID_HOTKEY_ID
local marker_hotkey_end_id				= obs.OBS_INVALID_HOTKEY_ID
local comment_count						= 0
local comments							= {}
local comment_hotkey_ids				= {}
local comment_end_hotkey_ids			= {}
local open_markers						= {}
local active_comment					= ""
local preset_filenames					= {}

-- video info stuff
local video_info 						= nil
local framerate 						= 30
local stream_output 					= nil
local recording_output 					= nil
local signal_handler 					= nil
local last_recording_frame_count		= 0
local last_stream_frame_count			= 0

-- functions and all that
local read_local_stream_marker_csv_file
local read_all_lines
local write_all_lines
local file_exists
local set_filename
local get_filename_from_path
local sanitize_filename
local replaceTrashyText
local string_to_csv_row
local hotkey_pressed
local hotkey_end_pressed
local mark_stream
local mark_end_stream
local on_event
local get_framerate
local update_ui_on_comments
local get_all_comment_preset_files
local save_preset_file
local read_preset_file
local load_preset_file
local sort_list
local print_log

------------------------------------------------------------------------------------------------------------------


-----== FILES SECTION ==-----
read_local_stream_marker_csv_file = function()
	-- check if using custom filename
	local output_file_name_actual = set_filename(output_file_name_current)

	-- add .csv extension if missing
	if not string.match(output_file_name_actual, output_file_extension) then
		output_file_name_actual = output_file_name_actual .. ".csv";
	end

	-- set output path as the script path by default
	output_path = script_path() .. output_file_name_actual;

	-- if specified output path exists, then set this as the new output path
	if (output_folder ~= "" and file_exists(output_folder)) then
		output_path = output_folder .. "/" .. output_file_name_actual
	end

	return obs.os_quick_read_utf8_file(output_path);
end


read_all_lines = function()
	local text = read_local_stream_marker_csv_file()
	if not text then return {} end

	local lines = {}
	for line in text:gmatch("[^\r\n]+") do
		table.insert(lines, line)
	end

	return lines
end


write_all_lines = function(path, lines)
	if not lines or #lines == 0 then
		return
	end

	local text = table.concat(lines, "\n") .. "\n"
	obs.os_quick_write_utf8_file(path, text, #text, false);
end


file_exists = function(path)
	local ok, err, code = os.rename(path, path)
	if not ok then
		if code == 13 then
			-- if file exists but OS denies permission to write
			print_log("Error writing to specified output folder. File is probably in use or system is preventing write access to the file. Output is saved in script path instead.");
		end
	end
	return ok, err;
end


set_filename = function(current_filename)
	-- 1. Set filename to the default
	local filename = output_file_name;
	-- 2. If set to use custom filename, proceed
	if use_custom_filename then
		-- 3. Fetch filename from custom syntax
		filename = output_file_name_custom
		-- 4. Check if filename has datetime in syntax
		if string.match(filename, "%[date%]") then
			-- 5. Set filename to the current filename (e.g. current date/time)
			-- 6. If set to reset date/time in filename, proceed to reset the filename
			if reset_custom_filename then
				local date_string = os.date(output_datetime_format)
				local escaped_date_death = replaceTrashyText(date_string)
				filename = filename:gsub("%[date%]", date_string):gsub("[^%w%-_ ]", "-")
			else
				filename = current_filename
			end
		end
		reset_custom_filename = false
	end
	output_file_name_current = filename
	return filename
end


get_filename_from_path = function(path)
	return path:match("^.+/(.+)$")
end


sanitize_filename = function(name)
	if not name or name == "" then
		return "unnamed"
	end

	-- Convert spaces to underscores
	name = name:gsub("%s+", "_")

	-- Remove invalid filename characters
	name = name:gsub("[\\/:*?\"<>|]", "")

	-- Remove control characters
	name = name:gsub("[%c]", "")

	-- Collapse multiple underscores
	name = name:gsub("_+", "_")

	-- Trim leading/trailing underscores
	name = name:gsub("^_+", ""):gsub("_+$", "")

	-- Windows: avoid trailing dot
	name = name:gsub("%.+$", "")

	if name == "" then
		return "unnamed"
	end

	return name
end


replaceTrashyText = function(str)
    return str:gsub("[%-%.%+%[%]%(%)%$%^%%%?%*]", "%%%1")
end


string_to_csv_row = function(text_to_process)
	local processed = text_to_process;

	processed = processed:gsub("$current_time", os.date("%Y-%m-%d %X"));
	processed = processed:gsub("$stream_start_time", stream_start_time);
	processed = processed:gsub("$stream_timestamp", stream_timestamp);
	processed = processed:gsub("$stream_mark_end_timestamp", stream_mark_end_timestamp);
	processed = processed:gsub("$recording_path", recording_path);
	processed = processed:gsub("$recording_filename", recording_filename);
	processed = processed:gsub("$recording_timestamp", recording_timestamp);
	processed = processed:gsub("$recording_mark_end_timestamp", recording_mark_end_timestamp);
	processed = processed:gsub("$recording_file_timestamp", recording_file_timestamp);
	processed = processed:gsub("$recording_file_mark_end_timestamp", recording_file_mark_end_timestamp);
	processed = processed:gsub("$comment", active_comment or "");

	return processed;
end


print_log = function(message)
	if show_log then
		print("[Local Stream Marker] " .. message)
	end
end


-----== MARKERS SECTION ==-----
hotkey_pressed = function(index)
	return function(pressed)
		if not pressed then return end

		active_comment = comments[index] or ""
		mark_stream(active_comment)
		active_comment = ""
	end
end


hotkey_end_pressed = function(index)
	return function(pressed)
		if not pressed then return end

		active_comment = comments[index] or ""
		mark_end_stream(active_comment)
		active_comment = ""
	end
end


mark_stream = function(active_comment)
	local stream_elapsed_time_sec = 0;
	local recording_elapsed_time_sec = 0;

	-- if streaming
	if obs.obs_frontend_streaming_active() then
		-- double-check stream output
		if stream_output ~= nil then
			local stream_frame_count = obs.obs_output_get_total_frames(stream_output);
			last_stream_frame_count = stream_frame_count
			stream_elapsed_time_sec = stream_frame_count / framerate
		end

		-- get streaming timestamp
		local stream_elapsed_hour = string.format("%02d", math.floor(stream_elapsed_time_sec / 3600));
		local stream_elapsed_minute = string.format("%02d", math.floor((stream_elapsed_time_sec % 3600) / 60));
		local stream_elapsed_second = string.format("%02d", math.floor(stream_elapsed_time_sec % 60));
		stream_timestamp = string.format("%s:%s:%s", stream_elapsed_hour, stream_elapsed_minute, stream_elapsed_second);
		stream_mark_end_timestamp = "n/a";
	else
		stream_timestamp = "n/a";
	end

	-- if recording
	if obs.obs_frontend_recording_active() then
		-- double-check recording output
		if recording_output ~= nil then
			local recording_frame_count = obs.obs_output_get_total_frames(recording_output);
			last_recording_frame_count = recording_frame_count
			recording_file_frame_count = recording_frame_count - recording_frame_count_on_split
			recording_elapsed_time_sec = recording_frame_count / framerate
			recording_file_elapsed_time_sec = recording_file_frame_count / framerate
		end

		-- get recording timestamp
		local recording_elapsed_hour = string.format("%02d", math.floor(recording_elapsed_time_sec / 3600));
		local recording_elapsed_minute = string.format("%02d", math.floor((recording_elapsed_time_sec % 3600) / 60));
		local recording_elapsed_second = string.format("%02d", math.floor(recording_elapsed_time_sec % 60));
		recording_timestamp = string.format("%s:%s:%s", recording_elapsed_hour, recording_elapsed_minute, recording_elapsed_second);
		recording_mark_end_timestamp = "n/a";

		-- get recording FILE timestamp (will differ from above if Automatic File Splitting is enabled)
		local recording_file_elapsed_hour = string.format("%02d", math.floor(recording_file_elapsed_time_sec / 3600));
		local recording_file_elapsed_minute = string.format("%02d", math.floor((recording_file_elapsed_time_sec % 3600) / 60));
		local recording_file_elapsed_second = string.format("%02d", math.floor(recording_file_elapsed_time_sec % 60));
		recording_file_timestamp = string.format("%s:%s:%s", recording_file_elapsed_hour, recording_file_elapsed_minute, recording_file_elapsed_second);
		recording_file_mark_end_timestamp = "n/a";
	else
		recording_timestamp = "n/a";
		recording_file_mark_end_timestamp = "n/a";
	end


	-- comment section
	active_comment = active_comment or ""

	local lines = read_all_lines(output_path)

	-- insert column headers if empty
	if #lines == 0 then
		table.insert(lines, output_format_header)
	end

	-- get formatted variables into a line
	local row = string_to_csv_row(output_format)

	-- insert line into table and write to file
	table.insert(lines, row)
	write_all_lines(output_path, lines)

    -- per-comment LIFO stack
    open_markers[active_comment] = open_markers[active_comment] or {}
    table.insert(open_markers[active_comment], #lines)

	print_log("START '" .. active_comment .. "' → row " .. #lines)
	return true;
end


mark_end_stream = function(active_comment)
	local stream_elapsed_time_sec = 0;
	local recording_elapsed_time_sec = 0;

	-- if streaming
	if obs.obs_frontend_streaming_active() then
		-- double-check stream output
		if stream_output ~= nil then
			local stream_frame_count = obs.obs_output_get_total_frames(stream_output);
			stream_elapsed_time_sec = stream_frame_count / framerate
		end

		-- get streaming timestamp
		local stream_elapsed_hour = string.format("%02d", math.floor(stream_elapsed_time_sec / 3600));
		local stream_elapsed_minute = string.format("%02d", math.floor((stream_elapsed_time_sec % 3600) / 60));
		local stream_elapsed_second = string.format("%02d", math.floor(stream_elapsed_time_sec % 60));
		stream_mark_end_timestamp = string.format("%s:%s:%s", stream_elapsed_hour, stream_elapsed_minute, stream_elapsed_second);
	end

	-- if recording
	if obs.obs_frontend_recording_active() then
		-- double-check recording output
		if recording_output ~= nil then
			local recording_frame_count = obs.obs_output_get_total_frames(recording_output);
			recording_file_frame_count = recording_frame_count - recording_frame_count_on_split
			recording_elapsed_time_sec = recording_frame_count / framerate
			recording_file_elapsed_time_sec = recording_file_frame_count / framerate
		end

		-- get recording timestamp
		local recording_elapsed_hour = string.format("%02d", math.floor(recording_elapsed_time_sec / 3600));
		local recording_elapsed_minute = string.format("%02d", math.floor((recording_elapsed_time_sec % 3600) / 60));
		local recording_elapsed_second = string.format("%02d", math.floor(recording_elapsed_time_sec % 60));
		recording_mark_end_timestamp = string.format("%s:%s:%s", recording_elapsed_hour, recording_elapsed_minute, recording_elapsed_second);

		-- get recording FILE timestamp (will differ from above if Automatic File Splitting is enabled)
		local recording_file_elapsed_hour = string.format("%02d", math.floor(recording_file_elapsed_time_sec / 3600));
		local recording_file_elapsed_minute = string.format("%02d", math.floor((recording_file_elapsed_time_sec % 3600) / 60));
		local recording_file_elapsed_second = string.format("%02d", math.floor(recording_file_elapsed_time_sec % 60));
		recording_file_mark_end_timestamp = string.format("%s:%s:%s", recording_file_elapsed_hour, recording_file_elapsed_minute, recording_file_elapsed_second);
	end


	-- comment section
	active_comment = active_comment or ""

	local queue = open_markers[active_comment]
	if not queue or #queue == 0 then
		print_log("END ignored: no open marker for '" .. active_comment .. "'")
		return
	end

	-- remove the latest marker for the associated commented marker
	local row_index = table.remove(queue)

	local lines = read_all_lines(output_path)
	if not lines[row_index] then return end

	-- parse fields (safe because we only modify known columns)
	local fields = {}
	for field in lines[row_index]:gmatch("([^,]+)") do
		fields[#fields + 1] = field
	end

	-- update ONLY end timestamps
	fields[4]  = stream_mark_end_timestamp
	fields[8]  = recording_mark_end_timestamp
	fields[10] = recording_file_mark_end_timestamp

	lines[row_index] = table.concat(fields, ", ")
	write_all_lines(output_path, lines)

	print_log("END '" .. active_comment .. "' → row " .. row_index)
	return true;
end


on_event = function(event)
	if event == obs.OBS_FRONTEND_EVENT_STREAMING_STARTED then
		stream_output = obs.obs_frontend_get_streaming_output();
		stream_start_time = os.date("%Y-%m-%d %X");
		stream_timestamp = "00:00:00";
		get_framerate()
		if not reset_custom_filename then
			reset_custom_filename = true;
		end
		print_log("Stream started: " .. os.date("%Y-%m-%d %X"));
	end
	
	if event == obs.OBS_FRONTEND_EVENT_RECORDING_STARTED then
		recording_output = obs.obs_frontend_get_recording_output();
		recording_timestamp = "00:00:00";
		get_framerate()
		if not obs.obs_frontend_streaming_active() and not reset_custom_filename then
			reset_custom_filename = true;
		end
		print_log("Recording started: " .. os.date("%Y-%m-%d %X"));
	end

	if event == obs.OBS_FRONTEND_EVENT_STREAMING_STOPPED then
		stream_output = nil
	end

	if event == obs.OBS_FRONTEND_EVENT_RECORDING_STOPPED then
		recording_output = nil
		recording_frame_count_on_split = 0
		obs.obs_data_release(output_settings)
		obs.obs_output_release(recording_output)
	else
		-- check if recording was split, get new name and reset timestamp
		-- credits to koala and upgradeQ in the OBS Forum for this (https://obsproject.com/forum/threads/failed-to-accomplish-work-with-lua-scripting.158774/)
		if obs.obs_frontend_recording_active() then
			local output_settings = obs.obs_output_get_settings(recording_output)

			-- obs.obs_output_get_id(recording_output) = get recording type ID
			---- ffmpeg_muxer = Standard
			---- ffmpeg_output = Custom Output (FFmpeg)
			---- mp4_output = Hybrid MP4 (thanks to MATT_bauer, Hydraa, and vorngorth1 for reporting the crash related to this)
			-- obs.obs_output_get_name(recording_output) = get recording type name
			---- adv_file_output = Standard
			---- adv_ffmpeg_output = Custom Output (FFmpeg)

			-- get path based on recording type (thanks to SnowRoach for reporting this)
			---- ffmpeg_muxer = "path"
			---- ffmpeg_output = "url"
			---- mp4_output = "path" (used by Hybrid MP4)
			local output_type = obs.obs_output_get_id(recording_output)
			if output_type == "ffmpeg_muxer" or output_type == "mp4_output" then
				recording_path = obs.obs_data_get_string(output_settings, "path")
			else
				recording_path = obs.obs_data_get_string(output_settings, "url")
			end
			signal_handler = obs.obs_output_get_signal_handler(recording_output)
			obs.signal_handler_connect(signal_handler, "file_changed", function(calldata)
				recording_path = obs.calldata_string(calldata, "next_file")
				recording_frame_count_on_split = obs.obs_output_get_total_frames(recording_output);
			end)
			recording_filename = get_filename_from_path(recording_path)
		end
	end
end


get_framerate = function()
	video_info = obs.obs_video_info()
	if obs.obs_get_video_info(video_info) then
		framerate = video_info.fps_num / video_info.fps_den
	end
end


-----== COMMENT SECTION ==-----
update_ui_on_comments = function(props, count)
	if comments_enabled then
		-- populate dropdown list with saved presets found in script folder
		local comment_preset_list_property = obs.obs_properties_add_list(
			props,
			"comment_preset_list",
			"Saved Presets",
			obs.OBS_COMBO_TYPE_EDITABLE,
			obs.OBS_COMBO_FORMAT_STRING
		)
		for _, preset_name in ipairs(sort_list(preset_filenames)) do
			obs.obs_property_list_add_string(
				comment_preset_list_property,
				preset_name,
				preset_filenames[preset_name]
			)
		end

		-- implement "on-change" to load selected preset
		obs.obs_property_set_modified_callback(comment_preset_list_property, function(props, property, settings)
			local preset_name = obs.obs_data_get_string(settings, "comment_preset_list")
			load_preset_file(props, preset_name)
			return true
		end)
		
		-- number of markers with comments (max 20, because... but who knows?)
		local comment_property = obs.obs_properties_add_int(props, "comment_count", "No. of Marker Comments", 0, 20, 1)
		obs.obs_property_set_modified_callback(comment_property, function(props, property, settings)
			update_ui_on_comments(props, obs.obs_data_get_int(settings, "comment_count"))
			return true
		end)

		-- save presets button
		obs.obs_properties_add_button(props, "save_comment_preset", " Save comment preset", save_preset_file
)

		-- add <count> number of comment fields
		for i = 1, count do
			obs.obs_properties_add_text(
				props,
				"comment_text_" .. i,
				"Comment " .. i,
				obs.OBS_TEXT_DEFAULT
			)
		end
	else
		-- clear comment section
		for i = 1, 20 do
			obs.obs_properties_remove_by_name(props, "comment_text_" .. i)
		end
		obs.obs_properties_remove_by_name(props, "comment_preset_list")
		obs.obs_properties_remove_by_name(props, "comment_count")
		obs.obs_properties_remove_by_name(props, "save_comment_preset")
	end
end


get_all_comment_preset_files = function()
	print_log("--- Searching for comment preset files in: " .. script_path() .. " ---")
	preset_filenames = {}

	-- set output path as the script path by default
	output_path = script_path() .. output_file_name_actual;

	-- if specified output path exists, then set this as the new output path
	if (output_folder ~= "" and file_exists(output_folder)) then
		output_path = output_folder .. "/" .. output_file_name_actual
	end
	
	local dir = obs.os_opendir(output_folder)
	if dir then
		local entry
		repeat
			entry = obs.os_readdir(dir)
			if entry then
				-- if not a directory, print file name
				if not entry.directory then
					-- Check if the file extension matches the desired type
					if obs.os_get_path_extension(entry.d_name) == preset_file_extension then
						local file_contents = read_preset_file(output_folder .. "/" .. entry.d_name)
						preset_filenames[file_contents[1]] = entry.d_name
						print_log("Found comment preset file: " .. entry.d_name)
					end					
                end
            end
        until not entry

		obs.os_closedir(dir)

		print_log("--- End search ---")
		return preset_filenames
	else
		print_log("Failed to open directory: " .. output_folder)
	end
end


save_preset_file = function(props, prop)
	-- get settings
	local number_of_comments = obs.obs_data_get_int(script_settings, "comment_count")
	local preset_name = obs.obs_data_get_string(script_settings, "comment_preset_list")
	local preset_name_clean = sanitize_filename(preset_name)
	local lines = {}
	table.insert(lines, preset_name)
	table.insert(lines, tostring(comment_count))
	for i = 1, comment_count do
		table.insert(lines, obs.obs_data_get_string(script_settings, "comment_text_" .. i))
	end

	-- set output
	local file_contents = table.concat(lines, "\n") .. "\n"
	local preset_file_path = script_path() .. "/" .. preset_name_clean .. ".markerpresets"
	obs.os_quick_write_utf8_file(preset_file_path, file_contents, #file_contents, false);
end


read_preset_file = function(preset_file_path)
	local text = obs.os_quick_read_utf8_file(preset_file_path)
	if not text then return {} end

	local lines = {}
	for line in text:gmatch("[^\r\n]+") do
		table.insert(lines, line)
	end

	return lines
end

load_preset_file = function(props, preset_name)
	local preset_name_clean = sanitize_filename(preset_name)
	local preset_file_path = script_path() .. "/" .. preset_name_clean .. ".markerpresets"
	local lines = read_preset_file(preset_file_path)
	if #lines < 2 then
		print_log("Preset file is invalid or empty: " .. preset_file_path)
		return
	end

	-- first line is preset name (ignored here)
	-- second line is comment count
	local count = tonumber(lines[2]) or 0
	obs.obs_data_set_int(script_settings, "comment_count", count)

	-- clear comment section
	for i = 1, 20 do
		obs.obs_properties_remove_by_name(props, "comment_text_" .. i)
	end
	
	-- add new fields
	for i = 1, count do
		obs.obs_properties_add_text(
			props,
			"comment_text_" .. i,
			"Comment " .. i,
			obs.OBS_TEXT_DEFAULT
		)
	end

	-- subsequent lines are comments
	for i = 1, count do
		local comment_text = lines[i + 2] or ""
		obs.obs_data_set_string(script_settings, "comment_text_" .. i, comment_text)
	end

	print_log("Loaded preset: " .. preset_name)
end


sort_list = function(t)
	local keys = {}
	for k in pairs(t) do
		table.insert(keys, k)
	end
	table.sort(keys)
	return keys
end


function script_properties()
	local properties = obs.obs_properties_create();

	local directory_property = obs.obs_properties_add_path(properties, "output_folder", "Output Folder", obs.OBS_PATH_DIRECTORY, nil, nil)
	obs.obs_property_set_long_description(directory_property, "The path where you want the output file (CSV) to be created.\n\nIf this is not specified or if there is an error in writing to this folder, the CSV file will be saved in the same folder as the script.");
	obs.obs_properties_add_button(properties, "mark_stream", " Set Marker ", mark_stream)

	-- datetime formats from https://www.lua.org/pil/22.1.html
	local datetime_formats = "    %a	abbreviated weekday name (e.g., Wed)\
	%A	full weekday name (e.g., Wednesday)\
	%b	abbreviated month name (e.g., Sep)\
	%B	full month name (e.g., September)\
	%c	date and time (e.g., 09/16/98 23:48:10)\
	%d	day of the month (16) [01-31]\
	%H	hour, using a 24-hour clock (23) [00-23]\
	%I	hour, using a 12-hour clock (11) [01-12]\
	%M	minute (48) [00-59]\
	%m	month (09) [01-12]\
	%p	either \"am\" or \"pm\" (pm)\
	%S	second (10) [00-61]\
	%w	weekday (3) [0-6 = Sunday-Saturday]\
	%x	date (e.g., 09/16/98)\
	%X	time (e.g., 23:48:10)\
	%Y	full year (1998)\
	%y	two-digit year (98) [00-99]\
	%%	the character `%´";
	obs.obs_properties_add_bool(properties, "output_use_custom_filename", "Use custom filename")
	obs.obs_properties_add_bool(properties, "show_log", "Show debug log")
	local custom_filename_property = obs.obs_properties_add_text(properties, "output_file_name_custom", "CSV Filename", obs.OBS_TEXT_DEFAULT)
	obs.obs_property_set_long_description(custom_filename_property, "If left blank, CSV file will be named \"obs-local-stream-marker.csv\"\n" .. datetime_formats);
	local datetime_format_property = obs.obs_properties_add_text(properties, "output_datetime_format", "Datetime Format", obs.OBS_TEXT_DEFAULT)
	obs.obs_property_set_long_description(datetime_format_property, "To use this, add [date] to the custom filename\nDo NOT \n" .. datetime_formats);

	obs.obs_properties_add_text(properties, "spacer_1", " ", obs.OBS_TEXT_INFO)

	-- comment section
	local comment_enabled_property = obs.obs_properties_add_bool(properties, "comments_enabled", "Comments for markers")
	obs.obs_property_set_long_description(comment_enabled_property, "Refresh this script to see the hotkeys in OBS settings, after finalizing the comments");
	obs.obs_property_set_modified_callback(comment_enabled_property, function(props, property, settings)
		update_ui_on_comments(props, obs.obs_data_get_int(settings, "comment_count"))
		return true
	end)

	-- add comment section inputs
	update_ui_on_comments(properties, comment_count)

	return properties;
end



function script_description()
	return [[
<h2>Local Stream Marker v1.11</h2>
<p>Use hotkeys to create markers on your stream or recording!</p>
<p>Go to <strong>Settings > Hotkeys</strong> and look for "<strong>[Local Stream Marker] Add stream mark</strong>" to set your hotkey.</p>
<p>Visit the documentation for more info: <a href="https://github.com/honganqi/OBS-Local-Stream-Marker">github.com/honganqi/OBS-Local-Stream-Marker</a></p>

<p>
<a href="https://twitch.tv/honganqi">twitch.tv/honganqi</a><br>
<a href="https://youtube.com/honganqi">youtube.com/honganqi</a><br>
<a href="https://discord.gg/G5rEU7bK5j">discord.gg/G5rEU7bK5j</a><br>
<a href="https://github.com/honganqi">github.com/honganqi</a><br>
</p>
<hr>
]];
end



function script_update(settings)
	output_folder = obs.obs_data_get_string(settings, "output_folder")
	output_file_name_custom = obs.obs_data_get_string(settings, "output_file_name_custom")
	use_custom_filename = obs.obs_data_get_bool(settings, "output_use_custom_filename")
	show_log = obs.obs_data_get_bool(settings, "show_log")
	output_datetime_format = obs.obs_data_get_string(settings, "output_datetime_format")
	get_framerate()

	-- convert Windows path to UNIX path
	output_folder = output_folder:gsub([[\]], "/");

	get_all_comment_preset_files()

	-- comment stuff
	comments_enabled = obs.obs_data_get_bool(settings, "comments_enabled")
	comment_count = obs.obs_data_get_int(settings, "comment_count")
	comments = {}
	for i = 1, comment_count do
		comments[i] = obs.obs_data_get_string(settings, "comment_text_" .. i)
	end

	script_settings = settings

	print_log("Script reloaded")
end

function script_defaults(settings)
	obs.obs_data_set_default_string(settings, "output_file_name_custom", output_file_name_custom)
	obs.obs_data_set_default_bool(settings, "output_use_custom_filename", false)
	obs.obs_data_set_default_bool(settings, "show_log", false)
	obs.obs_data_set_default_string(settings, "output_datetime_format", output_datetime_format)
	obs.obs_data_set_default_bool(settings, "comments_enabled", false)
end



function script_save(settings)
	local marker_hotkey_save_array = obs.obs_hotkey_save(marker_hotkey_id)
	obs.obs_data_set_array(settings, "marker_hotkey", marker_hotkey_save_array)
	obs.obs_data_array_release(marker_hotkey_save_array)

	local marker_hotkey_end_array = obs.obs_hotkey_save(marker_hotkey_end_id)
	obs.obs_data_set_array(settings, "marker_end_hotkey", marker_hotkey_end_array)
	obs.obs_data_array_release(marker_hotkey_end_array)

	-- comment stuff
	for i = 1, comment_count do
		local mark_id = "comment_hotkey_" .. i
		local mark_array = obs.obs_hotkey_save(comment_hotkey_ids[i])
		obs.obs_data_set_array(settings, mark_id, mark_array)
		obs.obs_data_array_release(mark_array)
	end

	for i = 1, comment_count do
		local end_id = "comment_end_hotkey_" .. i
		local end_array = obs.obs_hotkey_save(comment_end_hotkey_ids[i])
		obs.obs_data_set_array(settings, end_id, end_array)
		obs.obs_data_array_release(end_array)
	end
end


function script_load(settings)
	obs.obs_frontend_add_event_callback(on_event);
	marker_hotkey_id = obs.obs_hotkey_register_frontend("marker_hotkey", "[Local Stream Marker] Add stream mark", hotkey_pressed(0))
	marker_hotkey_end_id = obs.obs_hotkey_register_frontend("marker_end_hotkey", "[Local Stream Marker] Mark end", hotkey_end_pressed(0))
	local marker_hotkey_save_array = obs.obs_data_get_array(settings, "marker_hotkey")
	obs.obs_hotkey_load(marker_hotkey_id, marker_hotkey_save_array)	
	obs.obs_data_array_release(marker_hotkey_save_array)
	local marker_hotkey_end_array = obs.obs_data_get_array(settings, "marker_end_hotkey")
	obs.obs_hotkey_load(marker_hotkey_end_id, marker_hotkey_end_array)
	obs.obs_data_array_release(marker_hotkey_end_array)

	-- comment stuff
	local c_count = obs.obs_data_get_int(settings, "comment_count")
	for i = 1, c_count do
		-- MARK hotkey
		local mark_id = "comment_hotkey_" .. i

		comment_hotkey_ids[i] =
			obs.obs_hotkey_register_frontend(
				mark_id,
				"[Local Stream Marker] Comment " .. i,
				hotkey_pressed(i)
			)

		local mark_array = obs.obs_data_get_array(settings, mark_id)
		if mark_array then
			obs.obs_hotkey_load(comment_hotkey_ids[i], mark_array)
			obs.obs_data_array_release(mark_array)
		end

		-- END hotkey
		local end_id = "comment_end_hotkey_" .. i
		comment_end_hotkey_ids[i] =
			obs.obs_hotkey_register_frontend(
				end_id,
				"[Local Stream Marker] Comment " .. i .. " (End)",
				hotkey_end_pressed(i)
			)

		local end_array = obs.obs_data_get_array(settings, end_id)
		if end_array then
			obs.obs_hotkey_load(comment_end_hotkey_ids[i], end_array)
			obs.obs_data_array_release(end_array)
		end
	end

	read_local_stream_marker_csv_file()
end
