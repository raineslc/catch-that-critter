@echo off
rem The normal game (title screen, his real profile), with the local answer log on so
rem tools\summarize_playtest.py works on real play too.
call "%~dp0playtest_launch.cmd" --log
