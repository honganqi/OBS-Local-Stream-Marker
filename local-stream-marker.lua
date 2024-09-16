-- Local Stream Marker v1.10

obs 							= obslua

output_file_name 				= "obs-local-stream-marker.csv";
output_file_name_custom			= "obs-local-stream-marker [date]";
output_file_name_current		= "";
output_file_extension			= "%.csv$";
output_folder 					= "";
output_datetime_format			= "%Y-%m-%d";
use_custom_filename				= false;
reset_custom_filename			= true;
show_log						= false;

csv_headers 					= "Date Time, Stream Start, Stream Timestamp, Stream End Mark Timestamp, Recording Full Path, Recording Filename, Recording Timestamp, Recording End Mark Timestamp, Recording Timestamp on File, Recording End Mark Timestamp on File";
output_format 					= "$current_time, $stream_start_time, $stream_timestamp, $stream_mark_end_timestamp, $recording_path, $recording_filename, $recording_timestamp, $recording_mark_end_timestamp, $recording_file_timestamp, $recording_file_mark_end_timestamp";
recording_path					= "";
recording_filename 				= "";

stream_timestamp 				= "n/a";
stream_mark_end_timestamp		= "n/a";
recording_timestamp 			= "n/a";
recording_mark_end_timestamp	= "n/a";
recording_file_timestamp 		= "n/a";
recording_file_mark_end_timestamp = "n/a";
recording_file_frame_count 		= 0
recording_frame_count_on_split 	= 0
stream_start_time 				= "n/a";

marker_hotkey_id 				= obs.OBS_INVALID_HOTKEY_ID
marker_hotkey_end_id			= obs.OBS_INVALID_HOTKEY_ID

video_info 						= nil
framerate 						= 30
stream_output 					= nil
recording_output 				= nil
signal_handler 					= nil
last_recording_frame_count		= 0
last_stream_frame_count			= 0


------------------------------------------------------------------------------------------------------------------

function write_line_to_file(text, end_mark)
	-- convert Windows path to UNIX path
	output_folder = output_folder:gsub([[\]], "/");

	-- check if using custom filename
	local output_file_name_actual = set_filename(output_file_name_current)

	-- add .csv extension if missing
	if not string.match(output_file_name_actual, output_file_extension) then
		output_file_name_actual = output_file_name_actual .. ".csv";
	end

	-- set output path as the script path by default
	local script_path = script_path();
	local output_path = script_path .. output_file_name_actual;

	-- if specified output path exists, then set this as the new output path
	if (output_folder ~= "" and file_exists(output_folder)) then
		output_path = output_folder .. "/" .. output_file_name_actual
	end

	local file_contents = obs.os_quick_read_utf8_file(output_path);

	-- if file does not exist, create text with headers
	-- else get the contents and put in text
	if file_contents == nil then
		text = csv_headers .. "\n" .. text;
	else
		--text = file_contents .. "\n" .. text;

		if end_mark == true then
			-- Split file_contents into lines
			local lines = {}
			for line in file_contents:gmatch("[^\r\n]+") do
				lines[#lines + 1] = line
			end

			-- Replace the last line with "this is new" (if there is any line)
			if #lines > 0 then
				lines[#lines] = text
			end

			-- Concatenate all lines back to a single string
			text = table.concat(lines, "\n")
		else
			text = file_contents .. "\n" .. text;
		end
	end

	obs.os_quick_write_utf8_file(output_path, text, #text, false);
end


function set_filename(current_filename)
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



function file_exists(path)
	local ok, err, code = os.rename(path, path)
	if not ok then
		if code == 13 then
			-- if file exists but OS denies permission to write
			if show_log then
				print("Error writing to specified output folder. File is probably in use or system is preventing write access to the file. Output is saved in script path instead.");
			end
		end
	end
	return ok, err;
end



function replaceTrashyText(str)
    return str:gsub("[%-%.%+%[%]%(%)%$%^%%%?%*]", "%%%1")
end



function mark_stream()
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

	write_line_to_file(string_to_csv_row(output_format), false);
	return true;
end


function mark_end_stream()
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

	write_line_to_file(string_to_csv_row(output_format), true);
	return true;
end



function string_to_csv_row(text_to_process)
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

	return processed;
end



function hotkey_pressed(pressed)
	if not pressed then
		return
	end
    mark_stream()
end

function hotkey_end_pressed(pressed)
	if not pressed then
		return
	end
    mark_end_stream()
end



function on_event(event)
	if event == obs.OBS_FRONTEND_EVENT_STREAMING_STARTED then
		stream_output = obs.obs_frontend_get_streaming_output();
		stream_start_time = os.date("%Y-%m-%d %X");
		stream_timestamp = "00:00:00";
		get_framerate()
		if not reset_custom_filename then
			reset_custom_filename = true;
		end
		if show_log then
			print("[Local Stream Marker] Stream started: " .. os.date("%Y-%m-%d %X"));
		end
	end
	
	if event == obs.OBS_FRONTEND_EVENT_RECORDING_STARTED then
		recording_output = obs.obs_frontend_get_recording_output();
		recording_timestamp = "00:00:00";
		get_framerate()
		if not obs.obs_frontend_streaming_active() and not reset_custom_filename then
			reset_custom_filename = true;
		end
		if show_log then
			print("[Local Stream Marker] Recording started: " .. os.date("%Y-%m-%d %X"));
		end
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


function get_framerate()
	video_info = obs.obs_video_info()
	if obs.obs_get_video_info(video_info) then
		framerate = video_info.fps_num / video_info.fps_den
	end
end

function get_filename_from_path(path)
	return path:match("^.+/(.+)$")
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

	return properties;
end



function script_description()
	return [[
<h2>Local Stream Marker v1.10</h2>
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
	if show_log then
		print("[Local Stream Marker] Script reloaded")
	end
end

function script_defaults(settings)
	obs.obs_data_set_default_string(settings, "output_file_name_custom", output_file_name_custom)
	obs.obs_data_set_default_bool(settings, "output_use_custom_filename", false)
	obs.obs_data_set_default_bool(settings, "show_log", false)
	obs.obs_data_set_default_string(settings, "output_datetime_format", output_datetime_format)
end



function script_save(settings)
    local marker_hotkey_save_array = obs.obs_hotkey_save(marker_hotkey_id)
    obs.obs_data_set_array(settings, "marker_hotkey", marker_hotkey_save_array)
    obs.obs_data_array_release(marker_hotkey_save_array)

    local marker_hotkey_end_array = obs.obs_hotkey_save(marker_hotkey_end_id)
    obs.obs_data_set_array(settings, "marker_end_hotkey", marker_hotkey_end_array)
    obs.obs_data_array_release(marker_hotkey_end_array)
end



function script_load(settings)
	obs.obs_frontend_add_event_callback(on_event);
    marker_hotkey_id = obs.obs_hotkey_register_frontend("marker_hotkey", "[Local Stream Marker] Add stream mark", hotkey_pressed)
    marker_hotkey_end_id = obs.obs_hotkey_register_frontend("marker_end_hotkey", "[Local Stream Marker] Mark end", hotkey_end_pressed)
    local marker_hotkey_save_array = obs.obs_data_get_array(settings, "marker_hotkey")
    obs.obs_hotkey_load(marker_hotkey_id, marker_hotkey_save_array)	
    obs.obs_data_array_release(marker_hotkey_save_array)
    local marker_hotkey_end_array = obs.obs_data_get_array(settings, "marker_end_hotkey")
    obs.obs_hotkey_load(marker_hotkey_end_id, marker_hotkey_end_array)
    obs.obs_data_array_release(marker_hotkey_end_array)
end
