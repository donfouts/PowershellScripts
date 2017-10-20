$EpicPortal = '\\phm-los-upp01\c$\inetpub\wwwroot\EpicPortal\*'
$LocalEP = 'D:\EpicLocal\Portal\'
    
$EpicAppService = '\\phm-los-upp01\c$\inetpub\wwwroot\EpicAppService\*'
$LocalEAP = 'D:\EpicLocal\AppService\'

$DestinyLOS = '\\phm-los-upp01\c$\DestinyLOS\*'
$LocalDest = 'D:\EpicLocal\destinyLOS\'

$DestinyWebService = '\\phm-los-upp01\c$\inetpub\wwwroot\DestinyWebService\*'
$LocalDWS = 'D:\EpicLocal\DestinyWebService\'

$TPIService = '\\phm-los-ucomm01\c$\inetpub\wwwroot\TPIService\*'
$LocalTPI = 'D:\EpicLocal\TPIService\'

cp  $EpicAppService $LocalEAP -Recurse -Force -Verbose
cp  $EpicPortal $LocalEP -Recurse -Force -Verbose
cp  $DestinyLOS $LocalDest -Recurse -Force -Verbose
cp  $DestinyWebService $LocalDWS -Recurse -Force -Verbose
cp  $TPIService $LocalTPI -Recurse -Force -Verbose
