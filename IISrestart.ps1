#choose servers

$Dest = read-host 'Target- 1:DEV, 2:UAT, 3:PROD, 4:pppXX only  5:comm servers only' 

Switch ($Dest)
    {
      1{$servers = @("phm-los-dwap01","phm-los-dwap02", "phm-los-dcomm01")}
      2{$servers = @("phm-los-ucp01","phm-los-ucp02","phm-los-upp01","phm-los-upp02",'phm-los-ucomm01')}
      3{$servers = @("phm-los-pcp01","phm-los-pcp02","phm-los-ppp01","phm-los-ppp02", 'phm-los-pcomm01')}
      4{$servers = @("phm-los-ppp01","phm-los-ppp02", 'phm-los-pcomm01')}
      5{$servers = @("phm-los-pcomm01","phm-los-ucomm01","phm-los-dcomm01")} 
      6{$servers = @("phm-los-stg01")}
    }
    #
Foreach($a in $Servers){
  Write-host $a
  invoke-command -ComputerName $a -ScriptBlock {iisreset}
  }