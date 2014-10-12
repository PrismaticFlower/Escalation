echo off
spcomp Escalation.sp -o:../plugins/Escalation.smx DEV_BUILD="" USE_OBJECT_SAFETY_CHECK=""
echo.
echo You have compiled a developer build of Escalation. 
echo This build of the plugin contains added console (console, NOT admin) commands to assist in debugging the plugin.
echo Unless you have good reason you should use Compile Escalation.bat instead.
echo.
pause