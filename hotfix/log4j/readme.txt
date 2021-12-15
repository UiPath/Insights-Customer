Steps : 
    Open Insights_xx.xx.x_hotfix.zip
    Extract files to C:\Scripts
    Open powershell as Admin and run the Insights_xx.xx.x_hotfix.ps1 in C:\Scripts

***NOTE***
1. Script below requires 7zip and will attempt to download from the internet. If your machine is unable to connect to the internet please download and install it in the default location : C:\Program Files\7-Zip
2. Sisense.Shipper service may be disabled and the script below will log an error starting the service. This is the last step and does not impact patching. This service is not used for Insights and can be left Disabled.
***NOTE***
    Open fix_log4j_Sisense.zip
    Extract the zip file into C:\Scripts\ the stracture should be once unzipped C:\Scripts\fix_log4j
    Run as Admin the PowerShell file C:\Scripts\fix_log4j\fixLog4jSisense.ps1
    Review the logs under C:\Scripts\fix_log4j\log.txt and make sure there are no errors, in case there are ERRORs please consult with Sisense support