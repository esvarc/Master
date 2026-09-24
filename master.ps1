$_taskXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<Task version="1.3" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
 <RegistrationInfo>
  <Date>$((Get-Date).ToString('yyyy-MM-dd'))T00:01:00</Date>
  <Author>Run Santa</Author>
  <Description>Master AHK</Description>
  <Version>2.1.9</Version>
 </RegistrationInfo>
 <Triggers />
 <Principals>
  <Principal id="Author">
   <UserId>${env:USERDOMAIN}\${env:USERNAME}</UserId>
   <LogonType>InteractiveToken</LogonType>
   <RunLevel>HighestAvailable</RunLevel>
  </Principal>
 </Principals>
 <Settings>
  <MultipleInstancesPolicy>Parallel</MultipleInstancesPolicy>
  <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
  <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
  <AllowHardTerminate>false</AllowHardTerminate>
  <StartWhenAvailable>false</StartWhenAvailable>
  <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
  <IdleSettings>
   <StopOnIdleEnd>true</StopOnIdleEnd>
   <RestartOnIdle>false</RestartOnIdle>
  </IdleSettings>
  <AllowStartOnDemand>true</AllowStartOnDemand>
  <Enabled>true</Enabled>
  <Hidden>false</Hidden>
  <RunOnlyIfIdle>false</RunOnlyIfIdle>
  <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>
  <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
  <WakeToRun>false</WakeToRun>
  <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
  <Priority>4</Priority>
 </Settings>
 <Actions Context="Author">
  <Exec>
   <Command>$((Get-Command master).path)</Command>
   <Arguments></Arguments>
  </Exec>
 </Actions>
</Task>
"@
Register-ScheduledTask -Force -TaskName "Master" -TaskPath "\${env:USERNAME}\" -Xml $_taskXml