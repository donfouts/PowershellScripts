$dbserver = "PHM-APP-DMSQL01\DATAMART"
$dmartdb = "DMD_Data"
$insideserver = "PHM-Wb-SQL-FI02\sqlweb01"
$insideDB = "InsidePlazaHomeMortgage"
$genserver = "phm-db-gensql01"
$gendb ="Bizrules"
$Epicdbserver = "phm-los-pdb01\SQLLOSPROD"
$db = "Epic_PROD"

<#

'1JK','0TJ','09W','06\','02U','1Y?','078','1B3','1A=','26A','282','299'

#>

$aeid = @('14W')

$channel = 0
$2channel = 0
$Aes2build = "select ID from ClientImport where [Password] is null"
$newAEs = Invoke-Sqlcmd -ServerInstance $genserver -Database $gendb -Query $Aes2build
$string = "("
foreach($a in $newAEs.ID){$string = $string + "'$a',"}
$string = $string.Substring(0,$string.length -1)
$string = $string + ")"


$getclientssql = "SELECT * FROM Brokers WHERE idnum in $string and cur_status = 'APPROVED'"
#write-host $getclientssql

$clients = Invoke-Sqlcmd -Query $getclientssql -ServerInstance $dbserver -Database $dmartdb

$file = 'T:\Don\epic\imports\ClientEmailList\clientRest2.csv'

function Release-Ref ($ref) { 
([System.Runtime.InteropServices.Marshal]::ReleaseComObject( 
[System.__ComObject]$ref) -gt 0) 
[System.GC]::Collect() 
[System.GC]::WaitForPendingFinalizers() 
} 

$Excel = New-Object -ComObject Excel.Application
$Excel.Visible = $True
$ExcelWorkBook = $Excel.Workbooks.Open("T:\Don\epic\imports\ClientEmailList\clientRest2.xlsx")
$ExcelWorkSheet = $Excel.WorkSheets.item(1)
$ExcelWorkSheet.activate()

$lastRow = $ExcelWorkSheet.UsedRange.rows.count + 1
$Excel.Range("A" + $lastrow).Activate()

$NewCSVObject = @()


########################
#Client Loop
########################

foreach($c in $clients)
    {

    $killr = "select * from security_users where loginname like '$($c.idnum)_Admin'"
    $kill = invoke-sqlcmd -ServerInstance $Epicdbserver -Database $db -Query $killr
    if($kill.userid.Count -gt 0){
        write-host "User Already Created for: $($c.idnum)" -ForegroundColor Yellow
        continue;
    }
    
    $createflag = 0
    $otherclientssql = "SELECT * FROM Brokers WHERE [address] = '$($c.address)' and cur_status = 'APPROVED'"
    $otherclients = Invoke-Sqlcmd -ServerInstance $dbserver -Database $dmartdb -Query $otherclientssql
    if($otherclients.idnum.count -gt 1)
        {
        #check to see if the same AE has both channels
        $sameaesql = "select count(distinct(whole_rep_id)) as numb from brokers where [address] = '$($c.address)'"
        $sameAE = Invoke-Sqlcmd -ServerInstance $dbserver -Database $dmartdb -Query $sameaesql
        if($sameAE.numb -eq 2)
            {
            #has two different AE, treat this like two different Clients. 
            #only one channel
            #write-host $c.branch_type -ForegroundColor Yellow
            $channel = 0
            $2channel = 0

            switch($c.branch_type)
                {
                'B'{$channel = 6}
                'L'{$channel = 7}
                default {$channel = 0}
                }
            $PC = $channel
            $SC = 0
            $createflag = 1
            }
        ELSE
            {
            #single AE has both channles
            
            #get other clientid
            $ochannelinfo = "select idnum from brokers where [address] = '$($c.address)' and idnum <> '$($c.idnum)' and whole_rep_id is not null"
            $Oclient = Invoke-Sqlcmd -ServerInstance $dbserver -Database $dmartdb -Query $ochannelinfo
            #get primary channel
            $first = $c.idnum
            $second = $Oclient.idnum

            $DTbrokerLidget = "select top 1 * from brokers where idnum = '$first'"
            $DTbrokerLids = Invoke-Sqlcmd -Query $DTbrokerLidget -ServerInstance $dbserver -Database $dmartdb
            $DTbrokerBidget = "select top 1 * from brokers where idnum = '$second'"
            $DTbrokerBids = Invoke-Sqlcmd -Query $DTbrokerBidget -ServerInstance $dbserver -Database $dmartdb


            $maxvolget = "select top 1 branch_type, sum([loan_amt]) as vol from [gen] where brokers_id in ('$($DTbrokerBids.brokers_id)','$($DTbrokerLids.brokers_id)') and app_date > '2015-01-1 00:00:00.000' group by branch_type order by vol desc"


            $maxvol = invoke-sqlcmd -query $maxvolget -ServerInstance $dbserver -database $dmartdb 


            #write-host $maxvol.branch_type -ForegroundColor Green
            switch($maxvol.branch_type)
                {
                    'B'{
                        $channel = 6
                        $2channel = 7
                        #write-host "here"
                        }
                    'L'{
                        $channel = 7
                        $2channel = 6
                        }
                    default {$channel = 0}
                }
            $PC = $channel
            $SC = $2channel

            
            if($maxvol.branch_type -eq $c.branch_type){$createflag = 1}
            }
        }
        ELSE
            {
            #there is only one client with this nmls
            $channel = 0
            #write-host $c.branch_type -ForegroundColor Yellow
            switch($c.branch_type)
                {
                'B'{$channel = 6}
                'L'{$channel = 7}
                default {$channel = 0}
                }
            $PC = $channel
            $SC = 0
            $createflag = 1
            }

    #skip if this client is not the primary client
    if($createflag -eq 0)
        {
        Write-host "skiping non-primary ID: $($c.idnum)"
        #$skipids.WriteLine($c.id_num)
        continue;
        }ELSE{write-host "creating broker $($c.idnum)"}

    
    #create user import CSV
    #########################
    #username, Email, firstname, lastname, Integra1, sa, 1
    $nosuff = $($c.brok_record) -split ','
    $name = $nosuff[0] -split '\s+'
    $lname = $name[$name.count - 1] -replace "'",''
    $username = "$($c.idnum)_Admin" 
    $pa = -join ((65..90) + (97..122) | Get-Random -Count 5 | % {[char]$_})
    $pb = -join ((33..47) + (58..63) | Get-Random -Count 1 | % {[char]$_})
    $x = get-date
    $pc = $x.millisecond
    $password = $pa + $pb + $pc
    $row = New-Object -TypeName PSObject
    $row | Add-member -MemberType noteproperty -Name username -value $username
    $row | Add-Member -MemberType noteproperty -Name email -Value $($c.brok_email)
    $row | Add-Member -MemberType noteproperty -Name firstname -Value $name[0]
    $row | Add-Member -MemberType noteproperty -Name lastname -Value $lname
    $row | Add-Member -MemberType noteproperty -name password -Value $password
    $row | Add-Member -MemberType noteproperty -name dbname -Value 'sa'
    $row | Add-Member -MemberType noteproperty -name desktop -Value 1
    $row | Add-Member -MemberType NoteProperty -Name systemusertype -Value 0
    $row | Add-Member -MemberType NoteProperty -Name resetpasswordflag -Value 0

    $updateclientu = "update clientimport set [password] = '$password' where id = $($c.idnum)"
    Invoke-Sqlcmd -ServerInstance $genserver -Database $gendb -Query $updateclientu

    $NewCSVObject += $row

    $ExcelWorkSheet.Cells.Item($lastRow,1) = $c.brok_email
    $ExcelWorkSheet.Cells.Item($lastRow,2) = $c.idnum
    $ExcelWorkSheet.Cells.Item($lastRow,3) = $password
    $lastRow++

}

$NewCSVObject | Export-Csv $file -NoTypeInformation

$ExcelWorkBook.Save()
$ExcelWorkBook.Close()
$a = $Excel.Quit 
 
$a = Release-Ref($ExcelWorkSheet) 
$a = Release-Ref($ExcelWorkBook) 
$a = Release-Ref($Excel) 
Stop-Process -Name EXCEL -Force