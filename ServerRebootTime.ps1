$servers = @("phm-los-pcp01","phm-los-pcp02","phm-los-ppp01","phm-los-ppp02","phm-los-pcomm01","phm-los-ucp01","phm-los-ucp02","phm-los-upp01","phm-los-upp02","phm-los-ucomm01", "phm-los-dwap01", "phm-los-dwap02" , "phm-los-dcomm01")

foreach ($server in $servers){
    Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $server | Select csname, lastbootuptime 
}

