$Epicserver = "phm-los-pdb01\SQLLOSPROD"
$epicdb = "Epic_PROD"
$dmartserver = "PHM-APP-DMSQL01\DATAMART"
$dmartdb = "DMD_Data"
$insideserver = "PHM-Wb-SQL-FI02\sqlweb01"
$insideDB = "InsidePlazaHomeMortgage"
$genserver = "phm-db-gensql01"
$gendb ="Bizrules"

$sql = "select distinct(NMLSID) from crmbrokers where nmlsid <> '' and Branch_ID in (23,14,30,16) and [status] = 1"

$nmlsnums = Invoke-Sqlcmd -ServerInstance $insideserver -Database $insideDB -Query $sql

$notmade = 0
$made = 0
$active = 0

$html = @"
<html>
<style>
#NMLS {
	margin: 5px auto;
	width: 80%;
	min-height: 3em;
	padding: 10px;
	border: 2px solid black;
	position: relative;
}
#nmlsno {
	width: 2em;
	height: 100%;
	position: absolute;
	top:0;
	right:0;
	background-color:#023471;
}
#channelDIV{
	width:90%;
	height: 1.5em;
	background-color:White;
	border: 2px solid gray;
	margin:5px 5px 2px 5px;
}
#floater{
	Float:left;
	padding:2px 5px 2px 5px;
}
.verticaltext{
	transform: rotate(-90deg);
    transform-origin: right, top;
    -ms-transform: rotate(-90deg);
    -ms-transform-origin:right, top;
    -webkit-transform: rotate(-90deg);
    -webkit-transform-origin:right, top;
    position: absolute; 
    color: white;
}

</style>

<body>
<form action="/action_page.php" method="post">
"@

foreach($n in $nmlsnums)
{

    $killr = "select [status] as tot from CRMBrokers where NMLSID = '$($n.NMLSID)'"
    $kill = Invoke-Sqlcmd -ServerInstance $insideserver -Database $insideDB -Query $killr
    if($kill.tot -notcontains 1){continue;}

    $cid = @('');
    $hq =0
    $cor =0
    $branches =0
    $state = 0
    $skip = 0
    $ch1 = 0
    $ch2 = 0
    $hqBold = ""
    $hqBolde = ""
    $corBold = ""
    $corBolde = ""
    $DontMake = 0
    $sk =0
    $mainAE = 'blank'
    $secondaryAE = 'blank'

    write-host "---------------------"
    $HQclientR = "select * from CRMBrokers where nmlsid = '$($n.nmlsid)' and company like '%- HQ' and [status]=1 and Branch_ID in (23,14,30,16)"
    $HQc = Invoke-Sqlcmd -ServerInstance $insideserver -Database $insideDB -Query $HQclientR
    if($HQc.Company.Length -gt 0){
        #write-host $HQc.company
        $hq = 1
    }

    $CorclientR = "select * from CRMBrokers where nmlsid = '$($n.nmlsid)' and company like '%- COR' and [status]=1 and Branch_ID in (23,14,30,16)"
    $Corc = Invoke-Sqlcmd -ServerInstance $insideserver -Database $insideDB -Query $CorclientR
    if($Corc.Company.Length -gt 0){
        #write-host $Corc.company
        $cor = 1
    }

    $clientR = "select * from CRMBrokers where PlazaBroker_ID not in ('$($Corc.PlazaBroker_ID)','$($HQc.PlazaBroker_ID)') and nmlsid = '$($n.nmlsid)' and [status]=1 and Branch_ID in (23,14,30,16)"
    $clients = Invoke-Sqlcmd -ServerInstance $insideserver -Database $insideDB -Query $clientR
    foreach($client in $clients)
    {
        if($client.Company -match "- B\d{6}\Z")
        {
            #write-host $client.company
            $branches = 1
        }
        ELSE
        {
            $branches = 2
            #write-host "not Branch - "
            #write-host $client.company
           
        }
    }

    $hid = ''
    $cid = ''
    $NBid = ''
    
    $cidr = "select u.first_name + ' ' + u.last_name as AEname, b.brokers_id from brokers b join userinfo u on b.whole_rep_id = u.employ_id where idnum  = '$($Corc.PlazaBroker_ID)'"
    $cid = Invoke-Sqlcmd -ServerInstance $dmartserver -Database $dmartdb -Query $cidr
    $CorVolr = "select sum([Loan_amt]) as vol from [gen] where brokers_id = '$($cid.brokers_id)' and app_date > '2015-01-1 00:00:00.000'"
    $CorVol = Invoke-Sqlcmd -ServerInstance $dmartserver -Database $dmartdb -Query $CorVolr
    $hidr = "select u.first_name + ' ' + u.last_name as AEname, b.brokers_id from brokers b join userinfo u on b.whole_rep_id = u.employ_id where idnum  = '$($HQc.PlazaBroker_ID)'"
    $hid = Invoke-Sqlcmd -ServerInstance $dmartserver -Database $dmartdb -Query $hidr
    $hqVolr = "select sum([Loan_amt]) as vol from [gen] where brokers_id = '$($hid.brokers_id)' and app_date > '2015-01-1 00:00:00.000'"
    $hqVol = Invoke-Sqlcmd -ServerInstance $dmartserver -Database $dmartdb -Query $hqVolr

    #Volume compare
    if(($hq -eq 1) -and ($cor -eq 1))
    {   #get vol of both hq and corr

        #get brokers_id for both in Datamart
        $hidr = "select u.first_name + ' ' + u.last_name as AEname, b.brokers_id from brokers b join userinfo u on b.whole_rep_id = u.employ_id where idnum  = '$($HQc.PlazaBroker_ID)'"
        $cidr = "select u.first_name + ' ' + u.last_name as AEname, b.brokers_id from brokers b join userinfo u on b.whole_rep_id = u.employ_id where idnum  = '$($Corc.PlazaBroker_ID)'"
        $hid = Invoke-Sqlcmd -ServerInstance $dmartserver -Database $dmartdb -Query $hidr
        $cid = Invoke-Sqlcmd -ServerInstance $dmartserver -Database $dmartdb -Query $cidr

        $hqVolr = "select CAST(SUM([Loan_amt]) as int) as vol from [gen] where brokers_id = '$($hid.brokers_id)' and app_date > '2015-01-1 00:00:00.000'"
        $CorVolr = "select CAST(SUM([Loan_amt]) as int) as vol from [gen] where brokers_id = '$($cid.brokers_id)' and app_date > '2015-01-1 00:00:00.000'"
        $hqVol = Invoke-Sqlcmd -ServerInstance $dmartserver -Database $dmartdb -Query $hqVolr
        $CorVol = Invoke-Sqlcmd -ServerInstance $dmartserver -Database $dmartdb -Query $CorVolr
        
        if(([DBNull]::Value).Equals($hqVol.vol)){$hqVol.Vol = 0}
        if(([DBNull]::Value).Equals($CorVol.vol)){$CorVol.Vol = 0}

        if([int]$hqVol.vol -ge [int]$CorVol.vol)
        {
            write-host "hq higher vol" -forground yellow
            $hqBold = "<b>"
            $hqBolde = "</b>"
            $ch1 = 1
            $ch2 = 2
            $DontMake = 1
        }
        ELSE
        {
            $corBold = "<b>"
            $corBolde = "</b>"
            $ch1 = 2
            $ch2 = 1
            $DontMake = 2
        }
    }
    ELSE
    {
        if($hq -eq 1)
        {

            $ch1 = 1
            $ch2 = 0
        }
        if($cor -eq 1)
        {

            $ch1 = 2
            $ch2 = 0
        }

    }


    $color="#ffffff"
    
    $html = $html + " <div id='NMLS'><div id='nmlsno'><p class='verticaltext'>$($n.NMLSID)</p></div><table width='100%'><tbody>"
    
    
    #hq with branches

    if($hq -eq 1) 
    {

        write-host $HQc.Company -NoNewline -BackgroundColor White -ForegroundColor Black
        write-host " - " -NoNewline -BackgroundColor White -ForegroundColor Black
        write-host $HQc.PlazaBroker_ID -BackgroundColor White -ForegroundColor Black
        #status color
        $userr = "select top 1 resetpasswordflag from security_users where loginname like '$($HQc.PlazaBroker_ID)%'"
        $user = Invoke-Sqlcmd -ServerInstance $Epicserver -Database $epicdb -Query $userr
        if($user.resetpasswordflag.length -eq 1)
        {
            if($user.resetpasswordflag -eq 1)
            {
                $color ='#E5FFF3'
                $made++
                $state = 1
            }
            ELSE
            {
                $color='#E5F1FF'
                $active++
                $state = 2
            }
        }
        ELSE
        {
            $color = '#FFFFFF'
            $notmade++
        }
        
        
        $defaulted = ''
        $skipdefaultr = "select * from ClientImport where ID =$($HQc.PlazaBroker_ID)"
        $isskip = Invoke-Sqlcmd -ServerInstance $genserver -Database $gendb -Query $skipdefaultr
        #default the check box if clientimport table says so.

        if($isskip.Skip -eq 2){$defaulted = 'checked'}ELSE{$defaulted = ''}
        
        #bypass and default the creation of both if one is house account

        if($hid.AEname -match "^ACCOUNT.*HOUSE$")
        {
            write-host "house account HQ"
            $defaulted = 'checked'
            $ch1 = 1
            $ch2 = 0
        }
        $html = $html + "<tr bgcolor='$color'><td width='10%'> $hqBold $($HQc.PlazaBroker_ID) $HqBolde </td><td width='35%'>$hqBold $($HQc.Company)$hqBolde </td><td width='35%'>$hqBold $($HQc.address) $hqBolde </td><td width='15%'>$hqBold $($hqVol.vol) $hqBolde </td><td width='5%'><input type='checkbox' name='updatelist' value='$($HQc.PlazaBroker_ID)' $defaulted ></td></tr>"
        
        if($ch1 -eq 1){$sk = 2}ELSE{$sk = 1}
        $upClients = "update ClientImport set ch2 = $ch2, ch1 = $ch1 , [skip] = $sk, [state] = $state where ID = $($HQc.PlazaBroker_ID)"
        Invoke-Sqlcmd -ServerInstance $genserver -Database $gendb -Query $upClients  

        $mainAE = $hid.AEname
    } 
    ELSEIF(($hq -eq 0) -and ($branches -eq 2))   #no hq, non-branch 
    {
        write-host $client.Company -NoNewline
        write-host " - " -NoNewline
        write-host $client.PlazaBroker_ID
        $aer = "select top 1 u.first_name + ' ' + u.last_name as AEname, b.brokers_id, b.branch_type from brokers b join userinfo u on b.whole_rep_id = u.employ_id where b.idnum = '$($client.PlazaBroker_ID)'"
        $ae = Invoke-Sqlcmd -ServerInstance $dmartserver -Database $dmartdb -Query $aer

        $userr = "select top 1 resetpasswordflag from security_users where loginname like '$($client.PlazaBroker_ID)%'"
        $user = Invoke-Sqlcmd -ServerInstance $Epicserver -Database $epicdb -Query $userr
        if($user.resetpasswordflag.length -eq 1)
        {
            if($user.resetpasswordflag -eq 1)
            {
                $color ='#E5FFF3'
                $made++
                $state = 1
            }
            ELSE
            {
                $color='#E5F1FF'
                $active++
                $state = 2
            }
        }
        ELSE
        {
            $color = '#FFFFFF'
            $notmade++
        }
        
        $defaulted = ''
        $isskip = ''
        $skipdefaultr = ''
        $skipdefaultr = "select * from ClientImport where ID =$($client.PlazaBroker_ID)"
        $isskip = Invoke-Sqlcmd -ServerInstance $genserver -Database $gendb -Query $skipdefaultr
        #default the check box if clientimport table says so.
        if($isskip.Skip -eq 2){$defaulted = 'checked'}ELSE{$defaulted = ''}
        
        $html = $html + "<tr bgcolor='$color'><td width='10%'> $hqBold $($client.PlazaBroker_ID) $HqBolde </td><td width='35%'>$hqBold $($client.Company)$hqBolde </td><td width='35%'>$hqBold $($client.address) $hqBolde </td><td width='15%'>$hqBold $($NBVol.vol) $hqBolde </td><td width='5%'><input type='checkbox' name='updatelist' value='$($client.PlazaBroker_ID)' $defaulted ></td></tr>"
        #
        #get channel for branch

        if($ae.branch_type -eq 'B')
        {
            $ch1 = 1
            $ch2 = 0
        }
        ELSE 
        {
            $ch1 = 2
            $ch2 = 0
        }

        $upClients = "update ClientImport set ch2 = $ch2, ch1 = $ch1 , [skip] = 2, [state] = $state where ID = $($client.PlazaBroker_ID)"
        Invoke-Sqlcmd -ServerInstance $genserver -Database $gendb -Query $upClients  
        $mainAE = $ae.AEname

    }
    
    #if there was a cor
    if($cor -eq 1)
    {
        write-host $Corc.Company -NoNewline
        write-host " - " -NoNewline
        write-host $Corc.PlazaBroker_ID
        $userr = "select top 1 resetpasswordflag from security_users where loginname like '$($Corc.PlazaBroker_ID)%'"
        $user = Invoke-Sqlcmd -ServerInstance $Epicserver -Database $epicdb -Query $userr
        if($user.resetpasswordflag.length -eq 1)
        {
            if($user.resetpasswordflag -eq 1)
            {
                $color ='#E5FFF3'
                $made++
                $state = 1
            }
            ELSE
            {
                $color='#E5F1FF'
                $active++
                $state =2
            }
        }
        ELSE
        {
            $color = '#FFFFFF'
            $notmade++
        }
        
        $defaulted = ''
        $skipdefaultr = "select * from ClientImport where ID =$($Corc.PlazaBroker_ID)"
        $isskip = Invoke-Sqlcmd -ServerInstance $genserver -Database $gendb -Query $skipdefaultr
        #default the check box if clientimport table says so.
        if($isskip.Skip -eq 2){$defaulted = 'checked'}ELSE{$defaulted = ''}
        
        #bypass if ae is house account - make it any way
        if($cid.AEname -match "^ACCOUNT.*HOUSE$")
        {
            $defaulted = 'checked'
            $ch1 = 2
            $ch2 = 0
        }

        $html = $html + "<tr bgcolor='$color'><td width='10%'> $corBold $($Corc.PlazaBroker_ID) $corBold</td><td width='35%'>$corBold $($Corc.Company) $corBolde </td><td width='35%'>$corBold $($Corc.Address) $corBolde </td><td width='15%'>$corBold $($CorVol.vol) $corBolde</td><td width='5%'><input type='checkbox' name='updatelist' value='$($Corc.PlazaBroker_ID)' $defaulted ></td></tr>"        #if 
        #  

        if($DontMake -eq 2)
        {
            $upClients = "update ClientImport set ch2 = $ch2, ch1 = $ch1 , [skip] = 2, [state] = $state where ID = $($Corc.PlazaBroker_ID)"
            Invoke-Sqlcmd -ServerInstance $genserver -Database $gendb -Query $upClients   
        }
        ELSE
        {
            $upClients = "update ClientImport set ch2 = $ch2, ch1 = $ch1 , [skip] = 1, [state] = $state where ID = $($Corc.PlazaBroker_ID)"
            Invoke-Sqlcmd -ServerInstance $genserver -Database $gendb -Query $upClients 
        }
        $secondAE = $cid.AEname
    }
    $html = $html + "</tbody></table><br>$mainAE - $secondAE <br>"

    $state = 0

    if($branches -eq 1)
    {
    write-host "Branches"
    $html = $html + 'Branches'
        foreach($b in $Clients)
        {
            $color = '#FFFFFF'
            #get AE for the branch
            write-host $b.Company -NoNewline
            write-host " - " -NoNewline
            write-host $b.PlazaBroker_ID
            $aer = "select top 1 u.first_name + ' ' + u.last_name as AEname, b.brokers_id, b.branch_type from brokers b join userinfo u on b.whole_rep_id = u.employ_id where b.idnum = '$($b.PlazaBroker_ID)'"
            $ae = Invoke-Sqlcmd -ServerInstance $dmartserver -Database $dmartdb -Query $aer
            #get status for the branch
            
            $userr = "select top 1 resetpasswordflag from security_users where loginname like '$($b.PlazaBroker_ID)%'"
            $user = Invoke-Sqlcmd -ServerInstance $Epicserver -Database $epicdb -Query $userr
            if($user.resetpasswordflag.length -eq 1)
            {
                if($user.resetpasswordflag -eq 1)
                {
                    $color ='#E5FFF3'
                    $state = 1
                    $made++
                }
                ELSE
                {
                    $color='#E5F1FF'
                    $state = 2
                    $active ++
                }
            }
            ELSE
            {
                $color = '#FFFFFF'
                $notmade ++
            }

            #get channel for branch

            if($ae.branch_type -eq 'B')
            {
                $ch1 = 1
                $ch2 = 0
            }
            ELSE 
            {
                $ch1 = 2
                $ch2 = 0
            }
            $upClients = "update ClientImport set ch2 = $ch2, ch1 = $ch1 , [skip] = 2, [state] = $state where ID = $($b.PlazaBroker_ID)"
            Invoke-Sqlcmd -ServerInstance $genserver -Database $gendb -Query $upClients
            
            $defaulted = ''
            $skipdefaultr = "select * from ClientImport where ID =$($b.PlazaBroker_ID)"
            $isskip = Invoke-Sqlcmd -ServerInstance $genserver -Database $gendb -Query $skipdefaultr
            #default the check box if clientimport table says so.
            if($isskip.Skip -eq 2){$defaulted = 'checked'}ELSE{$defaulted = ''}
            
            $html = $html + "<div id='channelDIV' style='background-color:$color;'><div id='Floater'><input type='checkbox' name='updatelist' value='$($b.PlazaBroker_ID)' $defaulted ></div><div id='floater'>$($b.PlazaBroker_ID)</div><div id='floater'>$($b.Company)</div><div id='floater'>$($b.address)</div><div id='floater'>$($ae.AEname)</div></div>"
        }
    }
    $html = $html + "</div>"
}
$html = $html + "<input type='submit' value='submit'></form>"

$html | out-file "D:\DfoutsCode\Rolodex\clientdashboard\23183519.html"

write-host "Clients not imported: $notmade"
write-host "Clients imported: $made"
write-host "Clients active: $active"