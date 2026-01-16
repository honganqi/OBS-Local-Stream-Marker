# Changelog
All notable changes to this project will be documented in
this file.

## 1.12 - 2026/01/17 02:37 GMT+08:00
### Fixed
* Fixed a bug which broke the script on load caused by an unknown variable from an unclean cleanup (thanks, Piksure!)

## 1.11 - 2025/12/18 19:00 GMT+08:00
### Added
* Commented markers: an awesome idea by ryantheleach over at the OBS Forums! Please read the Readme or the description for more details.
### Changed
* Initialized all variables and functions with local scope
* Relocated functions by section
* General cleanup of semantics and functions
### Fixed
* Script was setting the wrong timestamps and durations possibly because the script was getting variables from other scripts. If this is confirmed to be fixed, this was because the variables were not initialized with local scope.

## 1.10 - 2024/09/16 18:07 GMT+08:00
### Changed
* Updated documentation in the `README.md` file and the script
### Fixed
* Fixed an error related to Hybrid MP4. This fixes the error: `258: bad argument #2 to 'gsub'` (thanks to MATT_bauer, Hydraa, and vorngorth1 for reporting the crash related to this)

## 1.9 - 2024/05/03 14:45 GMT+08:00
### Added
* Added a "Show debug log" to display log entries in OBS > Scripts > Script Log
### Fixed
* If the CSV filename has the `[date]` shortcode to add date and/or time in the filename, it now uses the date/time at the beginning of the streaming or recording session (in that order of priority). This was the intention from the start. Thanks, shookieTea (OBS Forums)!

## 1.8 - 2023/07/30 20:52 GMT+08:00
### Added
* Added an `Marker end` function with its own hotkey. Thanks, EmKeii!
* Added 3 new columns to the CSV file to accommodate the above: Stream End Mark Timestamp, Recording End Mark Timestamp, and Recording File End Mark Timestamp
* Added the "CSV Filename" field to enable the use of custom filenames.
* Added the ability to add dynamic date info to the custom filename with "Datetime Format". Add `[date]` to the custom filename to use this. e.g. "my-first-csv [date]" will result to "my-first-csv 2023-07-30". Characters not accepted in filenames will be changed to "-". Thanks, AlexNotTheLion!
* Added the "Datetime Format" field to enable custom datetime formats. e.g. `"%Y-%m-%d"` for `2023-07-30`, `"%B %d, %Y"` for `September 02, 2023`. If you are unsure of your datetime syntax, PLEASE SAVE YOUR WORK BEFORE TESTING THIS BECAUSE USING THE WRONG SYNTAX WILL CRASH YOUR OBS! You can test this by setting your datetime syntax, then hitting your "mark stream" hotkey to check if your file will be created. OBS will crash if it's not.
### Changed
* Timestamps now show "n/a" instead of "00:00:00" if a stream or recording is not active.

## 1.7 - 2023/07/07 02:01 GMT+08:00
### Fixed
* Sheesh... I didn't realize I released the version with a typo. This caused massive errors on the timestamps. I had the fixed one on my computer for months. On line 206, "framerate" is supposed to be "fps_num / fps_den" (numerator divided by denominator). Thanks, MistehTimmeh (OBS Forums)!

## 1.6 - 2023/03/21 11:24 GMT+08:00
### Fixed
* Creating stream markers for users who used frame rates not in whole numbers should work now (23.976, 29.97, 59.94). I misunderstood "fps_num" to be "fps_number" where it was actually "fps_numerator" so I had to get the "fps_den" (fps_denominator). Thanks to David Morales for reporting this issue.

## 1.5 - 2023/01/31 18:24 GMT+08:00
### Fixed
* Fixed the issue of the recording path not being detected when
using the `Custom Output (FFmpeg)` recording type instead of
`Standard`. The script previously assumed that it used the same
settings. Thanks to SnowRoach for reporting this.

## 1.4 - 2022/09/13 19:31 GMT+08:00
### Added
* Added a column named "Recording Path" in the created CSV file 
which includes the full path of the recording
* Added a column named "Recording Timestamp on File" in the
created CSV file. This will only differ from the "Recording
Timestamp" column if the Automatic File Splitting function
is enabled and used.
### Changed
* The "Recording Filename" column in the CSV file is now the
actual filename of the recording and also includes the path.
I forgot to indicate before that this was simply based on the
default syntax or format of OBS.

## 1.3 - 2022/09/12 12:24 GMT+08:00
### Fixed
* MAJOR: Fixed the issue where the script has erroneous
timestamps when used

## 1.2 - 2022/07/16 11:47 GMT+08:00
### Fixed
* Fixed the issue where 2 rows of column headers are created
instead of just 1

## 1.1 - 2022/02/04 23:41 GMT+08:00
### Changed
* Changed the Output Folder textbox to a Directory textbox
to allow the user to browse to a folder instead of manually
typing the path (thanks to JEJ)
### Fixed
* Fixed bug where if the specified path doesn't work, the
script fails to create or modify the CSV file in the scripts
folder

## 1.0 - 2022/01/21 05:39 GMT+08:00
* initial release