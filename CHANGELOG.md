# Changelog
All notable changes to this project will be documented in
this file.

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