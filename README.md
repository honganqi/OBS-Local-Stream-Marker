# Local Stream Marker

[![Latest Release](https://badgen.net/github/release/honganqi/OBS-Local-Stream-Marker "Latest Release")](https://github.com/honganqi/OBS-Local-Stream-Marker/releases/latest) 
![Downloads](https://img.shields.io/github/downloads/honganqi/OBS-Local-Stream-Marker/total "Downloads") ![GitHub Repo stars](https://badgen.net/github/stars/honganqi/OBS-Local-Stream-Marker "GitHub Repo stars") [![License](https://badgen.net/github/license/honganqi/OBS-Local-Stream-Marker "License")](https://github.com/honganqi/OBS-Local-Stream-Marker/blob/main/LICENSE) [![Discord](https://badgen.net/discord/members/EbwgmWwXF8?icon=discord&label "Discord")](https://discord.gg/EbwgmWwXF8) [![Buy Me A Coffee](https://badgen.net/badge/icon/Donate?icon=buymeacoffee&label "Donate through Buy Me A Coffee")](https://buymeacoffee.com/honganqi)

This script allows you to use a hotkey to create stream markers
or bookmarks for streams and recordings made on OBS.

## Description
Twitch has this function called `Add Stream Marker` where you
can add bookmarks to your livestream for review later. With
this script, you can have stream markers for any video made
with OBS even if you're not streaming! The stream markers will
be saved in a CSV file (comma separated values). You can open
this with a spreadsheet application like Microsoft Excel,
Google Sheets and the like. You may also open it with text
editors like Notepad.

Eleven (11) columns will be made:
1. Date and time when the stream/recording mark was made
2. Date and time when the stream started (if streaming)
3. Timestamp of the stream mark (if streaming)
4. Timestamp of the stream end mark (if streaming)
5. Full path to the file of the recording (if recording)
6. Filename of the recording (if recording)
7. Timestamp of the mark made on the recording (if recording)
8. Timestamp of the end mark made on the recording (if recording)
9. Timestamp of the mark made on the recording taking Automatic File Splitting into consideration (if recording)
10. Timestamp of the end mark made on the recording taking Automatic File Splitting into consideration (if recording)
11. Comment (if enabled and set)


## Usage
1. Download the ZIP file. You will only need `local-stream-marker.lua`. The others are just there for reading if you're bored.
1. In OBS, go to `Tools` -> `Scripts`.
3. Add the `local-stream-marker.lua` script: In the `Scripts` tab, click on `+` sign and browse to where this file is.
4. In the `Output Folder` text box, specify the path where you want the output file (CSV) to be created. If this is not specified, the CSV file will be saved in the same folder as the script.
5. The `Set Marker` button you see in this window is just here if you want to test this function while you don't have a hotkey set.
6. Enable `Use custom filename` if you want to use #7.
7. Use the `CSV Filename` if you want something other than the default `obs-local-stream-marker.csv`. Add `[date]` to the filename if you want to use #8.
8. Use `Datetime Format` to customize your datetime input in #7. e.g. `"%Y-%m-%d"` for `2023-07-30`, `"%B %d, %Y"` for `September 02, 2023`. If you are unsure of your datetime syntax, PLEASE SAVE YOUR WORK BEFORE TESTING THIS BECAUSE USING THE WRONG SYNTAX WILL CRASH YOUR OBS! You can test this by setting your datetime syntax, then hitting your "mark stream" hotkey to check if your file will be created. OBS will crash if it's not.
9. Once you're done with this window, go to `Settings` -> `Hotkeys` and look for the `[Local Stream Marker] Add stream mark` hotkey and add your specify your preferred hotkey.
10. You can set an optional end-marker in `[Local Stream Marker] Mark end`.
11. If you have the `[date]` shortcode to add #8 to your filename, the following settings will apply:
	1. If streaming or recording is not active, the timestamp when the first marker was made will be used for the filename.
	2. If streaming is active, the timestamp when the stream was started will be used for the filename. If there was a file created in #10.1, a new file will be created with this new filename with the new timestamp.
	3. If recording is active:
		1. If streaming, it will continue to use the existing file with the filename created with this new timestamp.
		2. If not streaming, it will create a new file with a filename similar to the case in #11.2.
12. Comments: See [Comments](./README.md#comments)


## Comments
You can add predefined comments and assign them to markers which you can then add to your CSV file with your hotkeys.
- Each marker has its own optional "End" hotkey. This marks the end of the "start".
- Markers are LIFO (last in, first out).
- If you use an "end" hotkey for a marker start that doesn't exist, it will not work. For example, you create a marker for "Comment 1", and then you hit the "Comment 1" hotkey to end it. If you hit that end marker again for "Comment 1", nothing will happen.
1. Enable `Comments for markers`
2. Set the `Number of Marker Comments` to the number of predefined comments you want to set.
3. Set your comments in the `Comment 1`, `Comment 2`, etc. text boxes.
4. Optionally, you can save your preset by setting a name in `Saved Presets` and then hitting the `Save comment preset` button.
	- This will create a file in the same location you set in `Output Folder` (same as your CSV files).
	- These files will be named after your preset name with the `.markerpresets` extension.
5. Refresh the script (with the reload button) to see the hotkeys appear in `Settings` -> `Hotkeys`.
6. After loading a preset, you'll also need to refresh the script to see the updated number of hotkeys in Settings.
7. A maximum of 20 comments is set because I don't know who in the world will be able to manage more than 20 hotkeys for 20 different markers/comments in a single session.
8. If you want to test your settings, you can start a recording to see how your hotkeys will work.
9. Please ALWAYS test your settings and your hotkeys.


## Notes
1. Make sure that your CSV file is not open in a spreadsheet app so the script can write to it.
2. The "Recording Timestamp on File" column will differ from the "Recording Timestamp" column only when the recording is split using Automatic File Splitting.

## Tutorial on YouTube
[![OBS Local Stream Marker tutorial! #obs](https://img.youtube.com/vi/kqZ8IEHLiYk/0.jpg)](https://www.youtube.com/watch?v=kqZ8IEHLiYk)

## Donations
[![Buy me A Coffee](https://sidestreamnetwork.net/wp-content/uploads/2021/06/white-button-e1624263691285.png "Buy Me A Coffee")](https://buymeacoffee.com/honganqi)

I would appreciate any support you send. If this has somehow
made you smile, made your day brighter, or made your work
easier and faster, please feel free to send me a smile, coffee,
pizza, a gamepad, t-shirt, or anything! Your support means a
lot to me as it will help cover a lot of costs. Thank you!

## Discord
Please feel free to join me on Discord!
[https://discord.gg/EbwgmWwXF8](https://discord.gg/EbwgmWwXF8)

[![Discord](https://discord.com/assets/f9bb9c4af2b9c32a2c5ee0014661546d.png)](https://discord.gg/EbwgmWwXF8)

## Notes
* This app is intended to be help you in your content creation
workflow. If you find that this is not the case, feel free to
remove this script from OBS, delete it, and purge it from your
memory; or maybe drop by the OBS forums or my Discord and send
some suggestions. Thank you!