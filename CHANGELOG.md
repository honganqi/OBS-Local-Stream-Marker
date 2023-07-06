# Changelog
All notable changes to this project will be documented in
this file.

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