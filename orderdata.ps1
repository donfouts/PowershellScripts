$Epicserver = "phm-los-pdb01\SQLLOSPROD"
$epicdb = "Epic_PROD"
$dmartserver = "PHM-APP-DMSQL01\DATAMART"
$dmartdb = "DMD_Data"
$insideserver = "PHM-Wb-SQL-FI02\sqlweb01"
$insideDB = "InsidePlazaHomeMortgage"

$sql = "Select * from CRMBrokers where [status] = 1"

$IDnums = Invoke-Sqlcmd -ServerInstance $insideserver -Database $insideDB -Query $sql

$htmlpath = D:\DfoutsCode\Rolodex\clientdashboard\main.html
$html = ""

foreach($x in $IDnums){

    #branch variables
    $l = 0   #1 = HQ, 2= COR, 3= Branch, 0=Standalone
    $s = 0   #1 = skip creating
    $c1 = 0
    $c2 = 0
    $shortname  = $x.Company
    $state = 0  #0 not created, 1 created, 2 user has logged in

    write-host $x.Company
    
    if($x.Company -match "- HQ\Z"){
        #write-host " - HQ"
        $l = 1
        $shortname = $x.Company

    }
    if($x.Company -match "- COR\Z"){
        #write-host " - COR"
        $l = 2
        $shortname = $x.Company.substring(0,$x.Company.Length - 5)
    }
    if($x.Company -match "- B\d{6}\Z"){
        #write-host " - Branch"
        $l = 3
        $shortname = $x.Company.substring(0,$x.Company.Length - 10)
    }
    #write-host $shortname

    #what channel(s)

    $chsql = "select distinct(branch_type) from brokers where nmls_reg_no = '$($x.NMLSID)'"
    $count = Invoke-Sqlcmd -ServerInstance $dmartserver -Database $dmartdb -Query $chsql

    if($count.Length -gt 1){
        write-host "dual $($x.NMLSID) - $($x.PlazaBroker_ID)"
        #get Default
        #this broker's channel
        $mychSQL = "select branch_type from brokers where idnum = '$($x.PlazaBroker_ID)'"
        $mych = Invoke-Sqlcmd -ServerInstance $dmartserver -Database $dmartdb -Query $mychSQL

        #get other channel
        $och = ''
        
        switch($mych.branch_type){
            'B'{
                $och = 'L'
                $ochsql = "select company, branch_type, idnum, brokers_id from brokers where nmls_reg_no = '$($x.NMLSID)' and Company like '%- COR' and branch_type = 'L'"
               }
            'L'{
                $och = 'B'
                $ochsql = "select company, branch_type, idnum, brokers_id from brokers where nmls_reg_no = '$($x.NMLSID)' and branch_type = 'B'"
                
                if($count.Length -gt 2){$ochsql = $ochsql + "and Company like '%- HQ'"}
               }
            default {$och = 'none'}
        }
        if($och -eq 'none'){
            write-host "can't get default channel"
            continue;
        }

        $oidr = Invoke-Sqlcmd -ServerInstance $dmartserver -Database $dmartdb -Query $ochsql

        #get Vol for my ch
        #get DT brokers_ID for this plaza id
        $dtbids = "select top 1 brokers_id from brokers where idnum = '$($x.PlazaBroker_ID)'"
        $dtbid = invoke-sqlcmd -ServerInstance $dmartserver -Database $dmartdb -Query $dtbids

        $myVolSql = "select sum([loan_amt]) as vol from [gen] where brokers_id ='$($dtbid.brokers_id)'"
        $myVolR = Invoke-Sqlcmd -ServerInstance $dmartserver -Database $dmartdb -Query $myVolSql

        #get vol for o id
        $OVolSql = "select sum([loan_amt]) as vol from [gen] where brokers_id ='$($oidr.brokers_id)'"
        $OVolR = Invoke-Sqlcmd -ServerInstance $dmartserver -Database $dmartdb -Query $OVolSql
        #Write-Host $ochsql
        #write-host "volume for channels: mine '$($mych.branch_type)' = $($myVolR.vol)"
        #write-host "volume for channels: Other '$och' = $($OVolR.vol)"
        $mvol = 0
        $ovol = 0
        $mvol = [int]$myVolR.vol
        $ovol = [int]$OvolR.vol

        if(($ovol -ne $null) -and ($mvol -ne $null))
        {
            if($mvol -gt $ovol)
            {
                $ch1 = $mych.branch_type
                $ch2 = $och
                #write-host "$ch1 is higher"
            
            }ELSE
            {
                $ch1 = $och
                $ch2 = $mych.branch_type
                #write-host "$ch2 is higher"
                #skip making this client because the ID used in the other channel will be created
                $s = 1
            }
        }
    } #end known 2 ch
    ELSE{
        #start of only 1 ch 
        $mychSQL = "select branch_type from brokers where idnum = '$($x.PlazaBroker_ID)'"
        $mych = Invoke-Sqlcmd -ServerInstance $dmartserver -Database $dmartdb -Query $mychSQL
        #set ch1
        $ch1 = $mych.branch_type
        #set ch2
        $ch2 = 0
    }  #end of single client

    #is it already created in Breeze?
    $bentityr = "select * from rolodex_entity where portaldomain = '$($x.PlazaBroker_ID)'"
   
    $bentity = Invoke-Sqlcmd -ServerInstance $Epicserver -Database $epicdb -Query $bentityr
    
    if($bentity.primarycontactid.length -gt 0)
    {
        $buserr = "select * from rolodex_contacts where contactid = $($bentity.primarycontactid)"
        $buser = Invoke-Sqlcmd -ServerInstance $Epicserver -Database $epicdb -Query $buserr

        #define status
        if($bentity.portaldomain.length -ge 1){$state + 1}
        if($buser.contactid.length -ge 1){$state + 1}
        write-host $state -BackgroundColor white -ForegroundColor Black
    }

    #find AE and branch of client
    $aer = "select u.Epic_ID, u.FirstName + ' ' + u.LastName as Name, upper(b.branchname) as branch from users u join Branches b on u.Branch_ID = b.Branch_ID where [User_ID] =$($x.AE_ID)"
    

    $ae = Invoke-Sqlcmd -ServerInstance $insideserver -Database $insideDB -Query $aer

    $aeID = $ae.epic_ID 
     $ae.branch
    
    $insert = "insert into ClientImport (ID,Ch1,Ch2,Company,Email,[Skip],[State],Branch,AE,NMLS,Addressline1)VALUES($($x.PlazaBroker_ID),'$ch1','$ch2','$shortname','$($x.ContactEmail)',$s,$state,'$($ae.branch)','$($ae.Epic_ID)',$($x.NMLSID),'$($x.Address)')"
    #Invoke-Sqlcmd -ServerInstance phm-db-gensql01 -Database Bizrules -Query $insert

}