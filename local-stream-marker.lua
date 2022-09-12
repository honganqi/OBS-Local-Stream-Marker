obs 							= obslua

output_file_name 				= "obs-local-stream-marker.csv";
output_folder 					= "";

csv_headers 					= "Date Time, Stream Start, Stream Timestamp, Recording Filename, Recording Timestamp";
output_format 					= "$current_time, $stream_start_time, $stream_timestamp, $recording_start_time, $recording_timestamp";

stream_timestamp 				= "00:00:00";
recording_timestamp 			= "00:00:00";
stream_start_time 				= "n/a";
recording_start_time 			= "n/a";

missed_frames_before_streaming 	= obs.obs_get_lagged_frames();
missed_frames_during_streaming 	= 0;
missed_frames_before_recording 	= obs.obs_get_lagged_frames();
missed_frames_during_recording 	= 0;

marker_hotkey_id 				= obs.OBS_INVALID_HOTKEY_ID

------------------------------------------------------------------------------------------------------------------

function write_to_file(text)
	-- convert Windows path to UNIX path
	output_folder = output_folder:gsub([[\]], "/");

	-- set output path as the script path by default
	local script_path = script_path();
	local output_path = script_path .. output_file_name;

	-- if specified output path exists, then set this as the new output path
	if (output_folder ~= "" and file_exists(output_folder)) then
		output_path = output_folder .. "/" .. output_file_name
	end

	local file_contents = obs.os_quick_read_utf8_file(output_path);

	-- if file does not exist, create text with headers
	-- else get the contents and put in text
	if file_contents == nil then
		text = csv_headers .. "\n" .. text;
	else
		text = file_contents .. "\n" .. text;
	end

	obs.os_quick_write_utf8_file(output_path, text, #text, false);
end

function is_empty(text)
	return s == nil or s == "";
end

function file_exists(path)
	local ok, err, code = os.rename(path, path)
	if not ok then
		if code == 13 then
			-- if file exists but OS denies permission to write
			print("Error writing to specified output folder. File is probably in use or system is preventing write access to the file. Output is saved in script path instead.");
		end
	end
	return ok, err;
end

function is_directory(path)
	return exists(path .. "/");
end

function mark_stream(properties, property)
	local stream_elapsed_time_sec = 0;
	local recording_elapsed_time_sec = 0;

	local video_info = obs.obs_video_info()
	if obs.obs_get_video_info(video_info) then
		framerate = video_info.fps_num
	end

	-- if streaming
	if obs.obs_frontend_streaming_active() then
		local stream_output = obs.obs_frontend_get_streaming_output();

		-- double-check stream output
		if stream_output ~= nil then
			-- frames missed due to rendering lag
			if obs.obs_get_lagged_frames() > 0 then
				missed_frames_during_streaming = obs.obs_get_lagged_frames() - missed_frames_before_streaming;
			end
			local stream_frame_count = obs.obs_output_get_total_frames(stream_output);
			stream_elapsed_time_sec = stream_frame_count / framerate
		end

		-- get streaming timestamp
		local stream_elapsed_hour = string.format("%02d", math.floor(stream_elapsed_time_sec / 3600));
		local stream_elapsed_minute = string.format("%02d", math.floor((stream_elapsed_time_sec % 3600) / 60));
		local stream_elapsed_second = string.format("%02d", math.floor(stream_elapsed_time_sec % 60));
		stream_timestamp = string.format("%s:%s:%s", stream_elapsed_hour, stream_elapsed_minute, stream_elapsed_second);
	end

	-- if recording
	if obs.obs_frontend_recording_active() then
		local recording_output = obs.obs_frontend_get_recording_output();

		-- double-check recording output
		if recording_output ~= nil then
			-- frames missed due to rendering lag
			if obs.obs_get_lagged_frames() > 0 then
				missed_frames_during_recording = obs.obs_get_lagged_frames() - missed_frames_before_recording;
			end
			local recording_frame_count = obs.obs_output_get_total_frames(recording_output);
			recording_elapsed_time_sec = recording_frame_count / framerate
		end

		-- get streaming timestamp
		local recording_elapsed_hour = string.format("%02d", math.floor(recording_elapsed_time_sec / 3600));
		local recording_elapsed_minute = string.format("%02d", math.floor((recording_elapsed_time_sec % 3600) / 60));
		local recording_elapsed_second = string.format("%02d", math.floor(recording_elapsed_time_sec % 60));
		recording_timestamp = string.format("%s:%s:%s", recording_elapsed_hour, recording_elapsed_minute, recording_elapsed_second);
	end

	write_to_file(process_string(output_format));
	return true;
end

function process_string(text_to_process)
	local processed = text_to_process;

	processed = processed:gsub("$current_time", os.date("%Y-%m-%d %X"));
	processed = processed:gsub("$stream_start_time", stream_start_time);
	processed = processed:gsub("$stream_timestamp", stream_timestamp);
	processed = processed:gsub("$recording_start_time", recording_start_time);
	processed = processed:gsub("$recording_timestamp", recording_timestamp);

	return processed;
end

function hotkey_pressed(pressed)
	if not pressed then
		return
	end
    mark_stream()
end

function on_event(event)
	if event == obs.OBS_FRONTEND_EVENT_STREAMING_STARTED then
		stream_start_time = os.date("%Y-%m-%d %X");
		missed_frames_before_streaming = obs.obs_get_lagged_frames();
		missed_frames_during_streaming = 0;
		stream_timestamp = "00:00:00";
		print("\nStream started: " .. os.date("%Y-%m-%d %X"));
	end
	
	if event == obs.OBS_FRONTEND_EVENT_RECORDING_STARTED then
		-- "filename" is based on default recording filename syntax of OBS
		recording_start_time = os.date("%Y-%m-%d %H-%M-%S.mkv");
		missed_frames_before_recording = obs.obs_get_lagged_frames();
		missed_frames_during_recording = 0;
		recording_timestamp = "00:00:00";
		print("\nRecording started: " .. os.date("%Y-%m-%d %X"));
	end
end

function script_properties()
	local properties = obs.obs_properties_create();

	local directory_property = obs.obs_properties_add_path(properties, "output_folder", "Output Folder", obs.OBS_PATH_DIRECTORY, nil, nil)
	obs.obs_property_set_long_description(directory_property, "The path where you want the output file (CSV) to be created.\n\nIf this is not specified or if there is an error in writing to this folder, the CSV file will be saved in the same folder as the script.");
    obs.obs_properties_add_button(properties, "mark_stream", " Set Marker ", mark_stream)

	return properties;
end

function script_description()
	return [[
<h2>Local Stream Marker v1.3</h2>
<p>Use hotkeys to create markers based on the timestamp of your stream or recording! A CSV file named "<strong>obs-local-stream-marker.csv</strong>" will be created which can be viewed with spreadsheet applications. Also, please make sure that your CSV file is not open in a spreadsheet app so the script can write to it.</p>
<p>Go to <strong>Settings > Hotkeys</strong> and look for "<strong>[Local Stream Marker] Add stream mark</strong>" to set your hotkey.</p>
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
	print("Local Stream Marker script reloaded")
end

function script_defaults(settings)
end

function script_save(settings)
    local marker_hotkey_save_array = obs.obs_hotkey_save(marker_hotkey_id)
    obs.obs_data_set_array(settings, "marker_hotkey", marker_hotkey_save_array)
    obs.obs_data_array_release(marker_hotkey_save_array)
end

function script_load(settings)
	obs.obs_frontend_add_event_callback(on_event);
    marker_hotkey_id = obs.obs_hotkey_register_frontend("marker_hotkey", "[Local Stream Marker] Add stream mark", hotkey_pressed)
    local marker_hotkey_save_array = obs.obs_data_get_array(settings, "marker_hotkey")
    obs.obs_hotkey_load(marker_hotkey_id, marker_hotkey_save_array)
    obs.obs_data_array_release(marker_hotkey_save_array)

	print("Local Stream Marker started");
end