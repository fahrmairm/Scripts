# LickHunterPro Powershell scripts

Install-LickHunterPro.ps1
- Checks and installs prerequisites NodeJS and PM2
- Downloads Latest LickHunterPro
- Asks what Exchange you want LickHunterPro to work on and copies only that part to scriptroot
- Copies the settings.py to the scriptroot and renames it to settings-%exchange%.py

Next you need to configure your settings-%echange%.py
Check http://www.lickhunter.com/settings/ for the explanation of the options to set
If running a new version of LickHunter Pro, always check the settings.py if some settings are new/changed, the bot can have issues if the settings are not right

Start-LickHunterPro.ps1
- Checks if the bot is running, if true, it stops the bot first before starting
- Checks if there is a new version of LickHunterPro and installs it
- If settings-%exchange%.py is changed, it auto creates a backup of that version
- Renames settings-%exchange%.py and copies it to the Websocket and Profit folder as settings.py
- Starts %exchange%websocket.exe, %exchange%profit.exe and bot monitor

Stop-LickHunterPro.ps1
- Stops LickHunterPro from running

# You are free to use these scipts, i'm not resposible for any loss you encounter because of my scipts #

 
