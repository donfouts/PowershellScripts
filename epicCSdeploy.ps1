$Dest = read-host 'Target - 1:DEV, 2:UAT, 3:PROD'

Switch($Dest){
  1{
      $EpicPortal = @('\\phm-los-dwap01\c$\inetpub\wwwroot\')
      $BrokerPortal = @('\\phm-los-dwap02\c$\inetpub\wwwroot\')
      $EpicAppService = @('\\phm-los-dwap01\c$\inetpub\wwwroot\')
      $BrokerAppService = @('\\phm-los-dwap02\c$\inetpub\wwwroot\')
      $DestinyLOS = @('\\phm-los-dcomm01\c$\','\\phm-los-dwap01\c$\','\\phm-los-dwap02\c$\')
      $DestinyWS = @('\\phm-los-dcomm01\c$\inetpub\wwwroot\','\\phm-los-dwap01\c$\inetpub\wwwroot\','\\phm-los-dwap02\c$\inetpub\wwwroot\')
      $tpi = @('\\phm-los-dcomm01\c$\inetpub\wwwroot\')
      $COM = @('\\phm-los-dcomm01\c$\')
  }
  2{
      $EpicPortal = @('\\phm-los-upp01\c$\inetpub\wwwroot\','\\phm-los-upp02\c$\inetpub\wwwroot\')
      $BrokerPortal = @('\\phm-los-ucp01\c$\inetpub\wwwroot\','\\phm-los-ucp02\c$\inetpub\wwwroot\')
      $EpicAppService = @('\\phm-los-upp01\c$\inetpub\wwwroot\','\\phm-los-upp02\c$\inetpub\wwwroot\')
      $BrokerAppService = @('\\phm-los-ucp01\c$\inetpub\wwwroot\','\\phm-los-ucp02\c$\inetpub\wwwroot\')
      $DestinyLOS = @('\\phm-los-ucomm01\c$\','\\phm-los-ucp01\c$\','\\phm-los-ucp02\c$\','\\phm-los-upp01\c$\','\\phm-los-upp02\c$\')
      $DestinyWS = @('\\phm-los-ucomm01\c$\inetpub\wwwroot\','\\phm-los-ucp01\c$\inetpub\wwwroot\','\\phm-los-ucp02\c$\inetpub\wwwroot\','\\phm-los-upp01\c$\inetpub\wwwroot\','\\phm-los-upp02\c$\inetpub\wwwroot\')
      $tpi = @('\\phm-los-ucomm01\c$\inetpub\wwwroot\')
      $COM = @('\\phm-los-ucomm01\c$\')
  }
  3{
      $EpicPortal = @('\\phm-los-ppp01\c$\inetpub\wwwroot\','\\phm-los-ppp02\c$\inetpub\wwwroot\')
      $BrokerPortal = @('\\phm-los-pcp01\c$\inetpub\wwwroot\','\\phm-los-pcp02\c$\inetpub\wwwroot\')
      $EpicAppService =
       @('\\phm-los-ppp01\c$\inetpub\wwwroot\','\\phm-los-ppp02\c$\inetpub\wwwroot\')
      $BrokerAppService = @('\\phm-los-pcp01\c$\inetpub\wwwroot\','\\phm-los-pcp02\c$\inetpub\wwwroot\')
      $DestinyLOS = @('\\phm-los-pcomm01\c$\','\\phm-los-pcp01\c$\','\\phm-los-pcp02\c$\','\\phm-los-ppp01\c$\','\\phm-los-ppp02\c$\')
      $DestinyWS = @('\\phm-los-pcomm01\c$\inetpub\wwwroot\','\\phm-los-pcp01\c$\inetpub\wwwroot\','\\phm-los-pcp02\c$\inetpub\wwwroot\','\\phm-los-ppp01\c$\inetpub\wwwroot\','\\phm-los-ppp02\c$\inetpub\wwwroot\')
      $tpi = @('\\phm-los-pcomm01\c$\inetpub\wwwroot\')
      $COM = @('\\phm-los-pcomm01\c$\')
}
  4{
      $EpicPortal = @('d:\ziptest\')
      $BrokerPortal = @('d:\ziptest\')
   }
}2

if(Test-Path D:\EpicStage\Portal){rni D:\EpicStage\Portal D:\EpicStage\EpicPortal}
if(Test-Path D:\EpicStage\AppService){rni D:\EpicStage\AppService D:\EpicStage\EpicAppService}


$deployEP = 'D:\EpicStage\EpicPortal\'
$deployBP = 'D:\EpicStage\EpicPortal\'
$deployEAP = 'D:\EpicStage\EpicAppService\'
$deployBAP = 'D:\EpicStage\EpicAppService\'
$deployDest = 'D:\EpicStage\destinyLOS\'
$deployDestws = 'D:\EpicStage\destinyWebService\'
$deploytpi = 'D:\EpicStage\TPIService\'
$deploycom = 'D:\EpicStage\COM\'

if(test-path $deploycom){
    foreach($x in $COM)
    {
        write-host "copy to $x" -BackgroundColor Black -ForegroundColor White
        copy-item $deploycom -destination $x -Recurse -Force
    }
}


if(test-path $deployEAP){
    foreach($x in $EpicAppService)
    {
        write-host "copy to $x" -BackgroundColor Black -ForegroundColor White
        copy-item $deployEAP -destination $x -Recurse -Force
    }
}

if(test-path $deployEP){
    foreach($x in $EpicPortal)
    {
        write-host "copy to $x" -BackgroundColor Black -ForegroundColor White
        Copy-Item $deployEP -destination $x -Recurse -Force
    }
}

if(test-path $deployBAP){
    foreach($x in $BrokerAppService)
    {
        write-host "copy to $x" -BackgroundColor Black -ForegroundColor White
        Copy-Item $deployBAP -Destination $x -Recurse -Force
    }
}

if(test-path $deployBP){
    foreach($x in $BrokerPortal)
    {
        write-host "copy to $x" -BackgroundColor Black -ForegroundColor White
        copy-item $deployBP -destination $x -Recurse -Force
    }
}

if(test-path $deployDest)
{
    foreach($x in $DestinyLOS)
    {
        write-host "copy to $x" -BackgroundColor Black -ForegroundColor White
        copy-item $deployDest -destination $x -Recurse -Force
    }
}

if(test-path $deployDestws)
{
    foreach($x in $DestinyWS)
    {
        write-host "copy to $x" -BackgroundColor Black -ForegroundColor White
        copy-item $deployDestws -destination $x -Recurse -Force
    }
}

if(test-path $deploytpi)
{
    foreach($x in $tpi)
    {
        write-host "copy to $x" -BackgroundColor Black -ForegroundColor White
        copy-item $deploytpi -destination $x -Recurse -Force
    }
}