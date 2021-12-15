Publish Date: December 14, 2021 

Version: 1.0 


UiPath Insights  

UiPath Insights versions prior to 2021.10 include Apache Log4j in the Java Connector that integrates UiPath code to Sisense and also in Sisense directly.  
 
UiPath has evaluated the code within the Java Connector and found that while a vulnerable version of the Apache Log4J library is included as a dependency, exploitation is mitigated by configuration. Regardless UiPath is issuing a hotfix to update this to the latest, non-vulnerable version of Apache Log4j. 

Sisense has also performed an investigation into their implementation and found that their installation has the vulnerable version of log4j. They have also determined that it is exploitable, but only by an authenticated and named user that has the proper privileges. No attack vectors are open from outside the application. 

 

Mitigation Steps for Insights: 

Steps : 

Open a browser and navigate to https://github.com/UiPath/Insights-Customer/tree/master/hotfix/log4j 

Select the hotfix that corresponds to your version of Insights to open that repository.  

Click on the Download button to download the zip file. 

From the download location, extract the zip files to C:\Scripts (You may need to create this directory) 

Open powershell as Admin and run the Insights_xx.xx.x_hotfix.ps1 in C:\Scripts 

cd C:\Scripts 

.\Insights_xx.xx.x_hotfix.ps1 

 

*Instructions Provided by Sisense* 

Go back to https://github.com/UiPath/Insights-Customer/tree/master/hotfix/log4j

Select the fix_log4j_Sisense.zip to open that repository 

Click on the Download button to download the zip file. 

Extract the zip file into C:\Scripts\ so that it creates a new folder called C:\Scripts\fix_log4j 

Open powershell as Admin and run C:\Scripts\fix_log4j\fixLog4jSisense.ps1 

Review the logs under C:\Scripts\fix_log4j\log.txt and make sure there are no errors, in case there are ERRORs please consult with Sisense support 
