# Local Stream Marker
This script allows you to use a hotkey to create stream markers
or bookmarks for streams and recordings made on OBS.

# Description
Twitch has this function called `Add Stream Marker` where you
can add bookmarks to your livestream for review later. With
this script, you can have stream markers for any video made
with OBS even if you're not streaming! The stream markers will
be saved in a CSV file (comma separated values). You can open
this with a spreadsheet application like Microsoft Excel,
Google Sheets and the like. You may also open it with text
editors like Notepad.

Seven (7) columns will be made:
* Date and time when the stream/recording mark was made
* Date and time when the stream started (if streaming)
* Timestamp of the stream mark (if streaming)
* Full path to the file of the recording (if recording)
* Filename of the recording (if recording)
* Timestamp of the mark made on the recording (if recording)
* Timestamp of the mark made on the recording taking Automatic File Splitting into consideration (if recording)


# Usage
1. Download the ZIP file. You will only need `local-stream-marker.lua`. The others are just there for reading if you're bored.
1. In OBS, go to `Tools` -> `Scripts`.
3. Add the `local-stream-marker.lua` script: In the `Scripts` tab, click on `+` sign and browse to where this file is.
4. In the `Output Folder` text box, specify the path where you want the output file (CSV) to be created. If this is not specified, the CSV file will be saved in the same folder as the script.
5. The `Set Marker` button you see in this window is just here if you want to test this function while you don't have a hotkey set.
6. Once you're done with this window, go to `Settings` -> `Hotkeys` and look for the `[Local Stream Marker] Add stream mark` hotkey and add your specify your preferred hotkey.
* Tutorial on YouTube: https://youtu.be/kqZ8IEHLiYk

## Donations
[![Buy me A Coffee](http://sidestream.tk/wp-content/uploads/2021/06/white-button-e1624263691285.png "Buy Me A Coffee")](https://buymeacoffee.com/honganqi)

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