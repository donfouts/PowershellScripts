$Prod = @("phm-los-pcomm01","phm-los-ppp01","phm-los-ppp02","phm-los-pcp01","phm-los-pcp02")
$UAT = @("phm-los-ucomm01","phm-los-upp01","phm-los-upp02","phm-los-ucp01","phm-los-ucp02")
$dev = @("phm-los-dcomm01","phm-los-dwap01","phm-los-dwap02")

#update destiny.exe version number

$z = "phm-los-dcomm01"
$service = @("LP - CL Server NEW","LP - PD Server NEW","LP - RF Server NEW","DU - CL Server","DU - PD Server","DU - RF Server","Flood - PD Server","Flood - RF Server","Flood - Web Server","License Server Service","Product Server")
foreach($x in $service){
    #get-service -computername $z -name $x | stop-service -Verbose
}
#Read-Host -Prompt "Press Enter to continue"


foreach($y in $UAT){
write-host $y

$applications = @('LPSTSCLServer.exe','CoreLogicRFServer.exe','CoreLogicPDServer.exe','CoreLogicWebServer.exe','DUCLServer32.exe','DUPDServer32.exe','DURFServer32.exe','ProductSetup.exe','ISSServiceMgr.exe','DestinyLOS-1.11.08.635.exe')
foreach($a in $applications){
    $Processes = Get-WmiObject -Class Win32_Process -ComputerName $y -Filter "name='$a'"

    foreach ($process in $processes) {
          $returnval = $process.terminate()
          $processid = $process.handle
 
        if($returnval.returnvalue -eq 0) {
          write-host "The process $ProcessName `($processid`) terminated successfully"
        }
        else {
          write-host "The process $ProcessName `($processid`) termination has some problems"
        }
    }
}


}
