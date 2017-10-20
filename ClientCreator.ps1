$dbserver = "PHM-APP-DMSQL01\DATAMART"
$dmartdb = "DMD_Data"
$insideserver = "PHM-Wb-SQL-FI02\sqlweb01"
$insideDB = "InsidePlazaHomeMortgage"
$genserver = "phm-db-gensql01"
$gendb ="Bizrules"

$Epicdbserver = "phm-los-pdb01\SQLLOSProd"
$db = "Epic_PROD"

#$madeids = [system.io.streamwriter] ".\made.txt"
#$skipids = [System.IO.StreamWriter] ".\skip.txt"

$aeid = '282'

$channel = 0
$2channel = 0

$getclientssql = "SELECT * FROM Brokers WHERE whole_rep_id in ('03I','06\','078','08\','09W','0C<','0OA','0S3','0TJ','0VR','1?V','1>X','12=','13R','14W','1A;','1A=','1B3','1D4','1D6','1F7','1H=','1IQ','1JK','1K4','1WI','1ZQ','2:U','20]','20O','26A','299') and cur_status = 'APPROVED'"
$clients = Invoke-Sqlcmd -Query $getclientssql -ServerInstance $dbserver -Database $dmartdb


########################
#Client Loop
########################

foreach($c in $clients)
    {
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
            $ochannelinfo = "select idnum from brokers where [address] = '$($c.address)' and idnum <> '$($c.idnum)'"
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
        }ELSE{#$madeids.WriteLine($c.id_num)}



    ###########################################################
    #Client create
    ###########################################################

    $ClientID = $c.idnum
    if($SC -eq 0){Write-host "Single Client"}ELSE{Write-host "Dual Client"}
    write-host $($c.Company) -NoNewline
    write-host $ClientID -NoNewline -ForegroundColor Yellow
    write-host $PC -NoNewline -ForegroundColor white
    write-host " - " -NoNewline
    write-host $SC -ForegroundColor white
    ######################################################################################

    ###############################################################
    $AEsql = "select c.contactid, c.alias, c.entityid, c.lastname, c.firstname, c.userid from rolodex_contacts c join rolodex_contactcategorylist l on c.contactid = l.contactid where alias = '$aeid'"
    $ae = Invoke-Sqlcmd -Query $AEsql -ServerInstance $Epicdbserver -Database $db

    if($ae.contactid -eq $null)
    {
    write-host "no AE with id $aeid"
    continue;
    }

    #write-host "$($ae.firstname) $($ae.lastname)" -BackgroundColor white -ForegroundColor Black

    $getbrokerssql = "select * from [DMD_Data].[dbo].brokers where idnum = '$ClientID'" 
    $b = Invoke-Sqlcmd -Query $getbrokerssql -ServerInstance $dbserver
    $EntitySQL = ''
    $contactsql = ''

    #get more info from CRMBrokers
        $crmsql = "SELECT top 1 * FROM CRMBrokers where PlazaBroker_ID = '$($b.idnum)'"
        $CRM = Invoke-Sqlcmd -Query $crmsql -ServerInstance $insideserver -Database $insideDB

        $networthsql = "select top 1 * from CRMCORCLients where CRMBroker_ID = '$($CRM.CRMBroker_ID)'"
        $crmcorclient = Invoke-Sqlcmd -Query $networthsql -ServerInstance $insideserver -Database $insideDB

       
        #VA Automatic
        $vaAuto = 0
        if($b.va_submit -eq '2222-02-22 00:00:00.000'){$vaAuto = 1}ELSE{$vaAuto = 0}

        #watchlist
        $watchlist = 'N'
        if($b.watchlst -eq 1){$watchlist = 'Y'}
        #get userid
        $username = "$($b.idnum)_Admin" 
        $getidsql = "select * from security_users where loginname = '$username'"
        $securityUser = Invoke-Sqlcmd -Query $getidsql -ServerInstance $Epicdbserver -Database $db 

        #add to security groups
        $scheck = "Select * from Security_groupsjoin where groupid = 29 and userid =$($securityUser.userid)"
        $d = Invoke-Sqlcmd -Query $scheck -ServerInstance $Epicdbserver -Database $db
        if($d.userid.count -eq 0){
            $sql1 = "insert into Security_groupsjoin (groupid, userid) VALUES (29,$($securityUser.userid))"
            Invoke-Sqlcmd -query $sql1 -ServerInstance $Epicdbserver -Database $db
               
            write-host "---------------added to client group----------------------"
        }ELSE{write-host "already in Client group"}

        $scheck = "Select * from Security_groupsjoin where groupid = 30 and userid =$($securityUser.userid)"
        $d = Invoke-Sqlcmd -Query $scheck -ServerInstance $Epicdbserver -Database $db
        if($d.userid.count -eq 0){
            $sql1 = "insert into Security_groupsjoin (groupid, userid) VALUES (30,$($securityUser.userid))"
            Invoke-Sqlcmd -query $sql1 -ServerInstance $Epicdbserver -Database $db
               
            write-host "---------------added to client admin group----------------------"
        }ELSE{write-host "already in Client admin group"}       
        

        #Entity exist Update / Insert?
        $sql11 = "select * from rolodex_entity where alias2 = '$($b.idnum)'"
        $checkclient = Invoke-Sqlcmd -Query $sql11 -ServerInstance $Epicdbserver -Database $db
        write-host "an entity with your name : $($b.idnum) / $($checkclient.name)  has $($checkclient.entityid.count) entries"
        

        if($checkclient.entityid.count -eq 0)
        {
            #get next entityid 
            $sql12 = "select top 1 entityid from rolodex_entity order by entityid desc"
            $lastentity = Invoke-Sqlcmd -Query $sql12 -ServerInstance $Epicdbserver -Database $db
            $EID = $lastentity.entityid + 1
            $makeEntity = 1
        }ELSE {
            $EID = $checkclient.entityid
            $makeEntity = 0
        }
        write-host "make entity is $makeEntity"
        #get CID
        #####################
        $CID = 0

        $sqlcon = "select * from rolodex_contacts where userid = $($securityUser.userid)"
        $checkcontact = Invoke-Sqlcmd -Query $sqlcon -ServerInstance $Epicdbserver -Database $db 
        write-host "a contact with your name: $username has $($checkcontact.contactid.count) entries"

        if($checkcontact.contactid.count -eq 0)
        {
            $sql122 = "select top 1 contactid from rolodex_contacts order by contactid desc"
            $lastContact = Invoke-Sqlcmd -Query $sql122 -ServerInstance $Epicdbserver -Database $db 
            $CID = $lastContact.contactid +1
            $makeContact = 1
        }ELSE{
            $CID = $checkcontact.contactid
            $makeContact = 0
        }
        
        if($makeEntity -eq 1){
           
            $EntitySQL = @"
            INSERT INTO [dbo].[rolodex_entity]
           ([city]
           ,[state]
           ,[zipcode]
           ,[country]
           ,[primarycontactid]
           ,[ediinterchangeid]
           ,[ediapplicationcode]
           ,[associatedaccountnumber]
           ,[vendoridnumber]
           ,[communicationuserid]
           ,[communicationuserpassword]
           ,[primarycontactdatabaseid]
           ,[hmdarespondentid]
           ,[hmdaregulatoryagencyid]
           ,[delivermethod]
           ,[county]
           ,[referencenumber]
           ,[lenderdatabaseid]
           ,[entityid]
           ,[name]
           ,[alias1]
           ,[alias2]
           ,[addressline1]
           ,[addressline2]
           ,[hmdapurchasertypeid]
           ,[licensedunderlawsofstate]
           ,[micode]
           ,[activeflag]
           ,[approval]
           ,[expiration]
           ,[licensenumber]
           ,[direct_endorsement]
           ,[hud_number]
           ,[va_automatic]
           ,[va_number]
           ,[wireaccountname]
           ,[wireaccountnumber]
           ,[wireabanumber]
           ,[legalentity]
           ,[licensedunderwhatlaw]
           ,[federallyregulatedflag]
           ,[naicnum]
           ,[financialrating]
           ,[accountingrating]
           ,[releasedate]
           ,[packagerecvdate]
           ,[approcalcode]
           ,[watchliststatus]
           ,[taxidnumber]
           ,[businesstype]
           ,[dateoffinancials]
           ,[fnmaapproval]
           ,[fhlmcapproval]
           ,[hudapproval]
           ,[vaapproval]
           ,[fhaapproval]
           ,[gnmaapproval]
           ,[commentid]
           ,[serverid]
           ,[mersidnumber]
           ,[overridezipcode]
           ,[transmittercontrolcode]
           ,[taxid]
           ,[merstype]
           ,[docmagicid]
           ,[DocMagicLID]
           ,[StatusID]
           ,[MailingAddressLine1]
           ,[MailingAddressLine2]
           ,[MailingCity]
           ,[MailingState]
           ,[MailingOverrideZipCode]
           ,[MailingZipCode]
           ,[EntityTypeID]
           ,[FHALicenseNumber]
           ,[FHAApprovalDate]
           ,[FHAExpiration]
           ,[FHAApplicationDate]
           ,[VALicenseNumber]
           ,[VAApprovalDate]
           ,[VAExpiration]
           ,[POADate]
           ,[AuthorizationDate]
           ,[AgreementDate]
           ,[VolumeThreshold]
           ,[AddlWireInfo]
           ,[WireRecvBankName]
           ,[WireRecvBankCity]
           ,[FHALenderID]
           ,[FHASponsorID]
           ,[EOIApproved]
           ,[EOIExpires]
           ,[EOIAmount]
           ,[GuardianSiteID]
           ,[GuardianCustNo]
           ,[loanapprovaldeliveryid]
           ,[lockconfirmationdeliveryid]
           ,[ratesheetdeliveryid]
           ,[costcenter]
           ,[impoundsglaccount]
           ,[intincglaccount]
           ,[loansheldglaccount]
           ,[miscfeesglaccount]
           ,[srpglaccount]
           ,[whfeesglaccount]
           ,[whintaccrglaccount]
           ,[yspglaccount]
           ,[floodserverid]
           ,[onlinedocscustcode]
           ,[sellerno]
           ,[completiondays]
           ,[serviceravailabledays]
           ,[serviceravailabletime1]
           ,[serviceravailabletime2]
           ,[disalloweditflag]
           ,[fidelitybankcode]
           ,[leadreturndays]
           ,[leadreturnhours]
           ,[leadreturnminutes]
           ,[bondissuer]
           ,[comericainvcode]
           ,[docutechpassword]
           ,[docutechusername]
           ,[furthercreditabanumber]
           ,[furthercreditaccountname]
           ,[furthercreditaccountnbr]
           ,[furthercreditrecvbankcity]
           ,[furthercreditrecvbankname]
           ,[leadfileextensions]
           ,[leadpath]
           ,[predprotectbranchid]
           ,[waivejurytrialflag]
           ,[institutiontype]
           ,[appraisalserverid]
           ,[serviceprovdiscflag]
           ,[availcreditdenialflag]
           ,[marksmanid]
           ,[predprotecthashpassword]
           ,[predprotectloginname]
           ,[licensecomparetype]
           ,[clahagentnumber]
           ,[confessofjudgmentflag]
           ,[servermicode]
           ,[cemobflag]
           ,[lenderliencodenum]
           ,[portaldomain]
           ,[suffixidnum]
           ,[borrowercompflag]
           ,[cemobmaxagecutoff]
           ,[lendercompflag]
           ,[nmlslicensenumber]
           ,[servicingbranchnum]
           ,[lenderaffiliateflag]
           ,[marksmancustomerid]
           ,[accounting_check_costcenter]
           ,[accounting_check_glnum]
           ,[accounting_lenderid]
           ,[accounting_wire_costcenter]
           ,[accounting_wire_glnum]
           ,[userid]
           ,[companyshortname]
           ,[titleserverid]
           ,[urladdress]
           ,[daylightsavingflag]
           ,[lockexpirationtime]
           ,[timezoneid]
           ,[expereorgidnum]
           ,[expereorgname]
           ,[smallcreditorflag]
           ,[drivebillingid]
           ,[drivepassword]
           ,[driveuserid]
           ,[cemobpremiumeom]
           ,[mrgbranchidnum]
           ,[legalentityidentifier]
           ,[dealerfidnum]
           ,[dealerloc]
           ,[dealertidnum]
           ,[delegatedflag]
           ,[indemnitydate]
           ,[indemnityexpirationdate]
           ,[usdaapprovalflag]
           ,[complianceeasehashpassword]
           ,[complianceeaseusername])
     VALUES
           ('$($CRM.City)'
           ,'$($CRM.State)'
           ,'$($CRM.Zip)'
           ,''
           ,$CID
           ,''
           ,''
           ,''
           ,''
           ,''
           ,''
           ,1
           ,''
           ,0
           ,0
           ,''
           ,''
           ,1
           ,$EID
           ,'$($CRM.DBA)'
           ,'$($CRM.Company)'
           ,'$($b.idnum)'
           ,'$($CRM.Address)'
           ,''
           ,0
           ,''
           ,0
           ,1
           ,convert(datetime,'1800-01-01 00:00:00.000')
           ,convert(datetime,'$($CRM.LicenseExpiration)')
           ,'$($b.lic_no)'
           ,0
           ,''
           ,$vaAuto
           ,'$taxidofFinancials'
           ,''
           ,''
           ,''
           ,''
           ,''
           ,'N'
           ,''
           ,''
           ,''
           ,convert(datetime,'1800-01-01 00:00:00.000')
           ,convert(datetime,'$($b.pack_recvd)')
           ,''
           ,'$watchlist'
           ,'$($b.tax_id)'
           ,''
           ,convert(datetime,'$($crmcorclient.NetWorthDate)')
           ,'N'
           ,'N'
           ,'N'
           ,'N'
           ,'N'
           ,'N'
           ,0
           ,0
           ,''
           ,0
           ,''
           ,'$($b.tax_id)'
           ,0
           ,''
           ,''
           ,1
           ,'$($CRM.Address)'
           ,''
           ,'$($CRM.City)'
           ,'$($CRM.State)'
           ,0
           ,'$($CRM.Zip)'
           ,0
           ,'$($b.fha_no)'
           ,convert(datetime,'$($b.fha_submit)')
           ,convert(datetime,'1800-01-01 00:00:00.000')
           ,convert(datetime,'1800-01-01 00:00:00.000')
           ,'$($b.va_no)'
           ,convert(datetime,'$($b.va_submit)')
           ,convert(datetime,'1800-01-01 00:00:00.000')
           ,convert(datetime,'1800-01-01 00:00:00.000')
           ,convert(datetime,'$($CRM.DateApproved)')
           ,convert(datetime,'$($CRM.FinancialsExpiration)')
           ,0
           ,''
           ,''
           ,''
           ,''
           ,''
           ,convert(datetime,'1800-01-01 00:00:00.000')
           ,convert(datetime,'1800-01-01 00:00:00.000')
           ,0
           ,''
           ,''
           ,0
           ,0
           ,0
           ,'$($b.region)'
           ,'','','','','','','','',0,'','',0,'',0,0,0,0,0,0,0,'','','','','','','','','','','','',0
           ,0
           ,0
           ,0
           ,0
           ,0
           ,''
           ,''
           ,1
           ,''
           ,0
           ,0
           ,0
           ,''
           ,'$($b.idnum)'
           ,''
           ,0
           ,0
           ,0
           ,'$($CRM.NMLSID)'
           ,''
           ,0
           ,''
           ,''
           ,''
           ,''
           ,''
           ,''
           ,$CID
           ,''
           ,0
           ,''
           ,0
           ,0
           ,0
           ,''
           ,''
           ,0
           ,''
           ,''
           ,''
           ,0
           ,''
           ,''
           ,''
           ,''
           ,''
           ,0
           ,convert(datetime,'1800-01-01 00:00:00.000')
           ,convert(datetime,'1800-01-01 00:00:00.000')
           ,0
           ,''
           ,'')
"@
            write-host "insert entity"
            #write-host $EntitySQL    
            }ELSE{
            $EntitySQL = @"
            UPDATE [dbo].[rolodex_entity]
               SET [city] = '$($CRM.City)'
                  ,[state] = '$($CRM.State)'
                  ,[zipcode] = '$($CRM.Zip)'
                  ,[primarycontactid] = $CID
                  ,[alias1] = '$($CRM.Company)'
                  ,[name] = '$($CRM.DBA)'
                  ,[alias2] = '$($b.idnum)'
                  ,[addressline1] = '$($CRM.Address)'
                  ,[licensenumber] = '$($b.lic_no)'
                  ,[va_automatic] = $vaAuto
                  ,[va_number] = '$($b.va_no)'
                  ,[taxidnumber] = '$($b.tax_id)'
                  ,[watchliststatus] = '$watchlist'
                  ,[dateoffinancials] = convert(datetime,'$($crmcorclient.NetWorthDate)')
                  ,[taxid] = '$($b.tax_id)'
                  ,[MailingAddressLine1] = '$($CRM.Address)'
                  ,[MailingCity] = '$($CRM.City)'
                  ,[MailingState] = '$($CRM.State)'
                  ,[MailingZipCode] = '$($CRM.Zip)'
                  ,[FHALicenseNumber] = '$($b.fha_no)'
                  ,[FHAApprovalDate] = convert(datetime,'$($b.fha_submit)')
                  ,[VALicenseNumber] = '$($b.va_no)'
                  ,[VAApprovalDate] = convert(datetime,'$($b.va_submit)')
                  ,[AuthorizationDate] = convert(datetime,'$($CRM.DateApproved)')
                  ,[costcenter] = '$($b.region)'
                  ,[portaldomain] = '$($b.idnum)'
                  ,[nmlslicensenumber] = '$($CRM.NMLSID)'
             WHERE Entityid = '$EID'
"@
            write-host "update entity"
            } #end of insert / update entity
        

        Invoke-Sqlcmd -query $EntitySQL -ServerInstance $Epicdbserver -Database $db
        ###################################################################################################

        #entity category
        
        if($makeEntity -eq 1){
            $insertCategory = "INSERT INTO [dbo].[rolodex_category_list]([lenderdatabaseid],[categoryid],[entitylenderdatabaseid],[entityid])VALUES(1,38,1,$EID)"
            Invoke-Sqlcmd -Query $insertCategory -ServerInstance $Epicdbserver -Database $db 

        }ELSE{
            $updatecategory = "UPDATE [dbo].[rolodex_category_list] SET [categoryid] = 38 WHERE entityid = $EID"
            Invoke-Sqlcmd -Query $updatecategory -ServerInstance $Epicdbserver -Database $db 
        }

        #Contact  Update / Insert

        if($makeContact -eq 1){
            $contactsql = @"
        INSERT INTO [dbo].[rolodex_contacts]
           ([lenderdatabaseid]
           ,[entityid]
           ,[contactid]
           ,[contactlenderdatabaseid]
           ,[lastname]
           ,[suffixname]
           ,[firstname]
           ,[middlename]
           ,[addressline1]
           ,[addressline2]
           ,[city]
           ,[state]
           ,[zipcode]
           ,[country]
           ,[title]
           ,[chumsid]
           ,[county]
           ,[associationdatabaseid]
           ,[associationid]
           ,[direct_endorsement]
           ,[hud_number]
           ,[va_automatic]
           ,[va_number]
           ,[activeflag]
           ,[approval]
           ,[expiration]
           ,[licensenumber]
           ,[alias]
           ,[serverid]
           ,[overridezipcode]
           ,[emailaddress]
           ,[PrefixName]
           ,[RateSheetDeliveryID]
           ,[LockConfirmationDeliveryID]
           ,[LoanApprovalDeliveryID]
           ,[EOIApproved]
           ,[EOIExpires]
           ,[EOIAmount]
           ,[userid]
           ,[floodserverid]
           ,[caivrsnumber]
           ,[gsa_date]
           ,[gsa_pagenumber]
           ,[ldp_date]
           ,[ldp_pagenumber]
           ,[appraisalserverid]
           ,[signaturefile]
           ,[predprotecthashpassword]
           ,[predprotectloginname]
           ,[licensecomparetype]
           ,[creditlifeid]
           ,[servermicode]
           ,[nmlslicensenumber]
           ,[titleserverid]
           ,[notaryexpirationdate])
     VALUES
           (1
           ,$EID
           ,$CID
           ,1
           ,'$($CRM.ContactLName)'
           ,''
           ,'$($CRM.ContactFName)'
           ,''
           ,'$($CRM.Address)'
           ,''
           ,'$($CRM.City)'
           ,'$($CRM.Stage)'
           ,'$($CRM.Zip)'
           ,''
           ,'Client Admin'
           ,''
           ,''
           ,0
           ,0
           ,0
           ,''
           ,0
           ,''
           ,1
           ,convert(datetime,'1800-01-01 00:00:00.000')
           ,convert(datetime,'1800-01-01 00:00:00.000')
           ,''
           ,''
           ,0
           ,0
           ,'$($CRM.ContactEmail)'
           ,''
           ,0
           ,0
           ,0
           ,convert(datetime,'1800-01-01 00:00:00.000')
           ,convert(datetime,'1800-01-01 00:00:00.000')
           ,0
           ,$($securityUser.userid)
           ,0
           ,''
           ,convert(datetime,'1800-01-01 00:00:00.000')
           ,0
           ,convert(datetime,'1800-01-01 00:00:00.000')
           ,0
           ,0
           ,''
           ,''
           ,''
           ,1
           ,''
           ,0
           ,''
           ,0
           ,convert(datetime,'1800-01-01 00:00:00.000'))
"@
            write-host "Insert contact"
        }ELSE{
            $contactsql = @"
            UPDATE [dbo].[rolodex_contacts]
               SET [lastname] = '$($CRM.ContactLName)'
                  ,[firstname] = '$($CRM.ContactFName)'
                  ,[addressline1] = '$($CRM.Address)'
                  ,[city] = '$($CRM.City)'
                  ,[state] = '$($CRM.Stage)'
                  ,[zipcode] = '$($CRM.Zip)'
                  ,[title] = 'Client Admin'
                  ,[activeflag] = 1
                  ,[emailaddress] = '$($CRM.ContactEmail)'
                  ,[userid] = $($securityUser.userid)
             WHERE contactid = $CID

"@
            write-host "update contact"
        } #end of contact update / insert

        Invoke-Sqlcmd -Query $contactsql -ServerInstance $Epicdbserver -Database $db 
        ####################################################################################################
        #Contact category Primary contact
        $catidget = "select * from rolodex_contactcategories where categoryname = 'Primary Contact'"
        $catid = Invoke-Sqlcmd -Query $catidget -ServerInstance $Epicdbserver -Database $db 
        $concat = $catid.categoryid

        $scheck = "select * from rolodex_contactcategorylist where entityid =$EID and contactid = $CID"
        $checkcat = Invoke-Sqlcmd -Query $scheck -ServerInstance $Epicdbserver -Database $db
        if($checkcat.entityid.count -lt 1){
             #$dropcontacts = "delete from rolodex_contactcategorylist where contactid = $CID"
             #Invoke-Sqlcmd -Query $dropcontacts -ServerInstance $Epicdbserver -Database $db
             ########################################################################################################
         
        
            $sql8 = "INSERT INTO [rolodex_contactcategorylist] ([lenderdatabaseid],[categoryid],[entitylenderdatabaseid],[entityid],[contactid],[contactlenderdatabaseid]) VALUES (1,$concat,1,$EID,$CID,1)"
            write-host "==================Contact Category ======================"
        
        
            Invoke-Sqlcmd -query $sql8  -ServerInstance $Epicdbserver -Database $db

            #Contact category Client Admin
            $catidget = "select * from rolodex_contactcategories where categoryname = 'Client Admin'"
            $catid = Invoke-Sqlcmd -Query $catidget -ServerInstance $Epicdbserver -Database $db 
            $concat = $catid.categoryid

            $scheck = "select * from rolodex_contactcategorylist where entityid =$EID and contactid = $CID"
            $checkcat = Invoke-Sqlcmd -Query $scheck -ServerInstance $Epicdbserver -Database $db
            if($checkcat.entityid.count -ge 1){
                 $dropcontacts = "delete from rolodex_contactcategorylist where contactid = $CID"
                 Invoke-Sqlcmd -Query $dropcontacts -ServerInstance $Epicdbserver -Database $db
                 ########################################################################################################
                 write-host "droping old contact categories"
            }
            $sql8 = "INSERT INTO [rolodex_contactcategorylist] ([lenderdatabaseid],[categoryid],[entitylenderdatabaseid],[entityid],[contactid],[contactlenderdatabaseid]) VALUES (1,$concat,1,$EID,$CID,1)"
            write-host "==================Contact Category ======================"
        
        
            Invoke-Sqlcmd -query $sql8  -ServerInstance $Epicdbserver -Database $db

            #Contact category Primary Contact
            $catidget = "select * from rolodex_contactcategories where categoryname = 'Primary Contact'"
            $catid = Invoke-Sqlcmd -Query $catidget -ServerInstance $Epicdbserver -Database $db 
            $concat = $catid.categoryid

            $sql8 = "INSERT INTO [rolodex_contactcategorylist] ([lenderdatabaseid],[categoryid],[entitylenderdatabaseid],[entityid],[contactid],[contactlenderdatabaseid]) VALUES (1,$concat,1,$EID,$CID,1)"
            write-host "==================Contact Category ======================"
        
        
            Invoke-Sqlcmd -query $sql8  -ServerInstance $Epicdbserver -Database $db
            ######################################################################################################
        }


        #Contact Associations
        $assget = "select * from setups_contactassociations where associationalias = 'EpicClientAdmin'"
        $assid = Invoke-Sqlcmd -Query $assget -ServerInstance $Epicdbserver -Database $db 
        $associationid = $assid.associationid

        $assql = "select * from rolodex_contactassociations where contactid = $CID and associationid = $associationid" 
        #write-host $assql

        $scheck = Invoke-Sqlcmd -Query $assql -ServerInstance $Epicdbserver -Database $db
        if($scheck.contactid.count -eq 0){
            $cassosql = "insert into rolodex_contactassociations ([associationdatabaseid],[associationid],[contactid],[contactlenderdatabaseid]) VALUES (1,$associationid,$CID,1)"
            Invoke-Sqlcmd -Query $cassosql -ServerInstance $Epicdbserver -Database $db 
            ################################################################################################################
        }ELSE{write-host "already has association"}

        #Contact Associations Primary Contact
        $assget = "select * from setups_contactassociations where associationalias = 'General Contact'"
        $assid = Invoke-Sqlcmd -Query $assget -ServerInstance $Epicdbserver -Database $db 
        $associationid = $assid.associationid

        $assql = "select * from rolodex_contactassociations where contactid = $CID and associationid = $associationid" 
        #write-host $assql

        $scheck = Invoke-Sqlcmd -Query $assql -ServerInstance $Epicdbserver -Database $db
        if($scheck.contactid.count -eq 0){
            $cassosql = "insert into rolodex_contactassociations ([associationdatabaseid],[associationid],[contactid],[contactlenderdatabaseid]) VALUES (1,$associationid,$CID,1)"
            Invoke-Sqlcmd -Query $cassosql -ServerInstance $Epicdbserver -Database $db 
            ################################################################################################################
        }ELSE{write-host "already has association"}

        #User Business channnel
        $check = "Select * from setups_channelsecurityuser where channelid = $PC and userid = $($securityUser.userid)"
        $buschan = Invoke-Sqlcmd -ServerInstance $Epicdbserver -Database $db -Query $check 
        if($buschan.userid.count -eq 0){
            $channelinsert = "insert into setups_channelsecurityuser (channelid, userid) VALUES ($PC,$($securityUser.userid))"
            write-host "access to $PC channel"
            Invoke-Sqlcmd -Query $channelinsert -ServerInstance $Epicdbserver -Database $db 
        }

        if($SC -ne 0){
            #User DUAL Business channnel
            $check = "Select * from setups_channelsecurityuser where channelid = $SC and userid = $($securityUser.userid)"
            $buschan = Invoke-Sqlcmd -ServerInstance $Epicdbserver -Database $db -Query $check 
            if($buschan.userid.count -eq 0){
                $channelinsert = "insert into setups_channelsecurityuser (channelid, userid) VALUES ($SC,$($securityUser.userid))"
                write-host "access to $SC channel"
                Invoke-Sqlcmd -Query $channelinsert -ServerInstance $Epicdbserver -Database $db 
            }
        }

        #Profile
        $SPcheck = "select * from security_userprofile where userid = $($securityUser.userid)"
        $SPResults = Invoke-Sqlcmd -query $SPcheck -ServerInstance $Epicdbserver -Database $db
        if($SPResults.userid.count -eq 0){
            $sql3 = "insert into [security_userprofile] (userid, loanstatusid, businesschannelid, referenceid) Values ($($securityUser.userid),33,$PC,'imprt')"
            Invoke-Sqlcmd -query  $sql3 -ServerInstance $Epicdbserver -Database $db 
            write-host "=====================user profile==========================="

        }ELSE{
            write-host "already has profile"
        }


        #client connection

        $SPcheck = "select * from security_userprofileentity where userid = $($securityUser.userid) and entityid = $EID"
        $SPResults = Invoke-Sqlcmd -query $SPcheck -ServerInstance $Epicdbserver -Database $db
        if($SPResults.userid.count -eq 0){

            $sql4 = "insert into security_userprofileentity (userid, businesschannelid, entitycategorydatabaseid, entitycategoryid, entitylenderdatabaseid, entityid) Values ($($securityUser.userid),$PC,1,38,1,$EID)"
            write-host "=======================Client Connection ====================="
            #write-host $sql4
            Invoke-Sqlcmd -query  $sql4 -ServerInstance $Epicdbserver -Database $db
        }
        #AE connection
        #get AID
        $AEget = "select * from security_userprofileentity where userid = $($ae.userid) and entitycategoryid = 43"
        $AEE = Invoke-Sqlcmd -Query $AEget -ServerInstance $Epicdbserver -Database $db 
        $AID = $AEE.entityid

        $SPcheck = "select * from security_userprofileentity where userid = $($securityUser.userid) and entityid = $AID"
        $SPResults = Invoke-Sqlcmd -query $SPcheck -ServerInstance $Epicdbserver -Database $db
        if($SPResults.userid.count -eq 0){

            $sql4 = "insert into security_userprofileentity (userid, businesschannelid, entitycategorydatabaseid, entitycategoryid, entitylenderdatabaseid, entityid) Values ($($securityUser.userid),$PC,1,43,1,$AID)"
            write-host "=======================AE Connection ====================="
            #write-host $sql4
            Invoke-Sqlcmd -query  $sql4 -ServerInstance $Epicdbserver -Database $db
        }


        #Branch connection
        #get BID
        $branchget = "select * from security_userprofileentity where userid = $($ae.userid) and entitycategoryid = 14"
        $branch = Invoke-Sqlcmd -Query $branchget -ServerInstance $Epicdbserver -Database $db 
        $BID = $branch.entityid

        $SPcheck = "select * from security_userprofileentity where userid = $($securityUser.userid) and entityid = $BID"
        $SPResults = Invoke-Sqlcmd -query $SPcheck -ServerInstance $Epicdbserver -Database $db
        if($SPResults.userid.count -eq 0){

            $sql4 = "insert into security_userprofileentity (userid, businesschannelid, entitycategorydatabaseid, entitycategoryid, entitylenderdatabaseid, entityid) Values ($($securityUser.userid),$PC,1,14,1,$BID)"
            write-host "=======================Branch Connection ====================="
            #write-host $sql4
            Invoke-Sqlcmd -query  $sql4 -ServerInstance $Epicdbserver -Database $db
        }

        #assign closer  (verified)
        $sql5 = "select Top 1 contactid from rolodex_contacts where entityid = $BID and lastname = '[Select Closer / Funder]'"
        #write-host $sql5
        $closercontact = Invoke-Sqlcmd -query $sql5 -ServerInstance $Epicdbserver -Database $db

        $SPcheck = "select * from [security_userprofilecontact] where userid = $($securityUser.userid) and entityid = $BID and contactid = $($closercontact.contactid)"
        $SPResults = Invoke-Sqlcmd -query $SPcheck -ServerInstance $Epicdbserver -Database $db 
        #write-host $SPResults.userid -ForegroundColor Yellow

        
        if($SPResults.userid.count -eq 0){
            $sql10 = @"
            INSERT INTO security_userprofilecontact
                   ([userid],[businesschannelid],[entitycategorydatabaseid],[entitycategoryid]
                   ,[entitylenderdatabaseid],[entityid],[contactcategorydatabaseid],[contactcategoryid],[contactlenderdatabaseid],[contactid])
             VALUES
                   ($($securityUser.userid),$PC,1,14,1,$BID,1,49,1,$($closercontact.contactid))
"@ 
            write-host "==================Assign closer to profile ========================"
            #write-host $sql10

            Invoke-Sqlcmd -Query $sql10  -ServerInstance $Epicdbserver -Database $db
        }

        #Corp connection
        $SPcheck = "select * from security_userprofileentity where userid = $($securityUser.userid) and entityid = 86"
        $SPResults = Invoke-Sqlcmd -query $SPcheck -ServerInstance $Epicdbserver -Database $db
        if($SPResults.userid.count -eq 0){

            $sql4 = "insert into security_userprofileentity (userid, businesschannelid, entitycategorydatabaseid, entitycategoryid, entitylenderdatabaseid, entityid) Values ($($securityUser.userid),$PC,1,46,1,86)"
            write-host "=======================Corporate connection ====================="
            #write-host $sql4
            Invoke-Sqlcmd -query  $sql4  -ServerInstance $Epicdbserver -Database $db
        }

        #Licenses
        #get licenses from datamart

        #hardcoded license type 1-whole, 2-minicorr, 3-retail

        $licget = "select * from brkstate where brokers_id = '$($b.brokers_id)'"
        $licenses = Invoke-Sqlcmd -Query $licget -ServerInstance $dbserver -Database $dmartdb

        foreach($l in $licenses){
            $lientype = ''
            if($PC -eq 6)
                {
                $epiclienchannel = 1
                }
            if($PC -eq 7)
                {
                $epiclienchannel = 2
                }

            $inslic = @"
            INSERT INTO [dbo].[rolodex_entitylicensing]
           ([approveddate]
           ,[expirationdate]
           ,[lenderdatabaseid]
           ,[entityid]
           ,[state]
           ,[lienposition]
           ,[licensenumber]
           ,[appraisaltype]
           ,[submitteddate]
           ,[LicenseTypeID]
           ,[LicenseExemptionID])
     VALUES
           (convert(datetime,'$($l.lic_expire3)')
           ,convert(datetime,'$($l.lic_expire)')
           ,1
           ,$EID
           ,'$($l.st_abbr)'
           ,'1st'
           ,'$($l.lic_no)'
           ,''
           ,convert(datetime,'1800-01-01 00:00:00.000')
           ,$epiclienchannel
           ,0)
"@
            $check = "select * from rolodex_entitylicensing where state = '$($l.st_abbr)' and entityid = $EID and licensetypeid = $epiclienchannel "
            $skip = Invoke-Sqlcmd -Query $check -ServerInstance $Epicdbserver -Database $db 
            if($skip.entityid.count -eq 0){
                Invoke-Sqlcmd -Query $inslic -ServerInstance $Epicdbserver -database $db 
                write-host "insert license for $($l.st_abbr)"

            #if both channels - add to both channels
            if($SC -ne 0)
                {
                $lientype = ''
                if($SC -eq 6)
                    {
                    $epiclienchannel = 1
                    }
                if($SC -eq 7)
                    {
                    $epiclienchannel = 2
                    }

               $inslic = @"
                INSERT INTO [dbo].[rolodex_entitylicensing]
               ([approveddate]
               ,[expirationdate]
               ,[lenderdatabaseid]
               ,[entityid]
               ,[state]
               ,[lienposition]
               ,[licensenumber]
               ,[appraisaltype]
               ,[submitteddate]
               ,[LicenseTypeID]
               ,[LicenseExemptionID])
         VALUES
               (convert(datetime,'$($l.lic_expire3)')
               ,convert(datetime,'$($l.lic_expire)')
               ,1
               ,$EID
               ,'$($l.st_abbr)'
               ,'1st'
               ,'$($l.lic_no)'
               ,''
               ,convert(datetime,'1800-01-01 00:00:00.000')
               ,$epiclienchannel
               ,0)
"@
                $check = "select * from rolodex_entitylicensing where state = '$($l.st_abbr)' and entityid = $EID and licensetypeid = $epiclienchannel "
                $skip = Invoke-Sqlcmd -Query $check -ServerInstance $Epicdbserver -Database $db 
                if($skip.entityid.count -eq 0){
                    Invoke-Sqlcmd -Query $inslic -ServerInstance $Epicdbserver -database $db 
                    write-host "insert license for $($l.st_abbr) on secondary channel"
                }
            }ELSE{write-host "license already in"}
            }
        } #end of licenses

        #Compensation

        $compget = "select * from ActorPlans where actor_id = '$($b.actor_id)' order by effective_date asc"
        $complans = Invoke-Sqlcmd -Query $compget -ServerInstance $dbserver -Database $dmartdb 
        
        #sequence seed number
        $c = 1
        
        #delete old comp plans - only works while testing, for future updates will need to append not remove the old
        ############
        $delplans = "select * from [rolodex_entitycompensation] where entityid = $EID"
        Invoke-Sqlcmd -Query $delplans -ServerInstance $Epicdbserver -Database $db 

        if($delplans.entityid.count -lt 1){
        foreach($p in $complans){
            
            $dam = 0
            $pam = 0
            $cam = 0
            $fam = 0
            if(!$p.dollar_amt){$dam = 0}ELSE{$dam = $p.dollar_amt}
            if(!$p.ceiling_amt){$cam = 0}ELSE{$cam = $p.ceiling_amt}
            if(!$p.floor_amt){$fam = 0}ELSE{$fam = $p.floor_amt}
            if(!$p.plan_pct){$pam = 0}ELSE{$pam = $p.plan_pct}

            $insCplan = @"
            INSERT INTO [dbo].[rolodex_entitycompensation]
           ([effectivedate]
           ,[entityid]
           ,[entrydate]
           ,[flatamount]
           ,[lenderdatabaseid]
           ,[maximumamount]
           ,[minimumamount]
           ,[percentage]
           ,[plusflag]
           ,[sequencenumber]
           ,[state])
     VALUES
           (convert(datetime,'$($p.effective_date)')
           ,$EID
           ,convert(datetime,'$($p.added_date)')
           ,$dam
           ,1
           ,$cam
           ,$fam
           ,$pam
           ,1
           ,$c
           ,'')
"@
            
        $compcheck = "select * from rolodex_entitycompensation where entityid = $EID and "
        
        Invoke-Sqlcmd -Query $insCplan -ServerInstance $Epicdbserver -Database $db 

        write-host "comp plan $c effective $($p.effective_date)"
        $c ++
        } #end of comp plans

        }

        #Products
        $products = @()
        if($b.loan_type_conv -eq 1){
            $addproducts = "select * from ps_product where productalias in ('SF15','SF20','SF30','CF100','CA1012L','CF150','CF200','CF300','CA512L','CA712L','RCF15DURP','RCF15DURPX','RCF20DURP','RCF20DURPX','RCF30DURP','RCF30DURPX','RCF30DURPH','EJA101','EJF15','EJF30','EJA51','EJA71','EPJA101','EPJF15','EPJF30','EPJA51','EPJA71','RCF15','RCF20','RCF30','RCF30HB','RCF15FR','RCF30FR','CA101LHB','CF150HB','CF200HB','CF300HB','CA51LHB','CA71LHB','CF30HP','CA51HP','CF150HR','CF300HR','CF150HRHB','CF300HRHB','CF150HS','CF300HS','CF150HSHB','CF300HSHB','CF150LPRR','RCF15LPRRX','CF200LPRR','RCF20LPRRX','CF300LPRR','RCF30LPRRX','CF300LPRRH','PPJA101','PPJF15','PPJF30','PPJA51','PPJA71','CA101LSC','CF150SC','CF300SC','CA51LSC','CA71LSC')"
            $convProducts = Invoke-Sqlcmd -Query $addproducts -ServerInstance $Epicdbserver -Database $db 
            foreach($i in $convProducts){$products += $i.productid}
        }
        if($b.loan_type_va -eq 1){
            $addproducts = "select * from ps_product where productalias in ('VA150','VA200','VA300','VA51T','VA150IRRRL','VA15IRRRLR','VA200IRRRL','VA20IRRRLR','VA300IRRRL','VA30IRRRLR','VAJ30IRRRL','VAJ30IRRLR','VAJUMBO15','VAJUMBO30','VAJ51T')"
            $convProducts = Invoke-Sqlcmd -Query $addproducts -ServerInstance $Epicdbserver -Database $db 
            foreach($i in $convProducts){$products += $i.productid}
        }
        if($b.loan_type_fha -eq 1){
            $addproducts = "select * from ps_product where productalias in ('FHA150','FHA200','FHA30KS','FHA30HKS','FHA30K','FHA30HK','FHA300','FHA51T','FHA150HB','FHA300HB','FHA51THB','FHA15S','FHA20S','FHA30S','FHA300HBS','FHA150D','FHA300D','FHA51TD','FHA30DK','FHA30DKS','FHA150HBD','FHA300HBD','FHA51THBD','FHA30HDK','FHA30HDKS')"
            $convProducts = Invoke-Sqlcmd -Query $addproducts -ServerInstance $Epicdbserver -Database $db 
            foreach($i in $convProducts){$products += $i.productid}
        }
        if($b.loan_type_usda -eq 1){
            $addproducts = "select * from ps_product where productalias in ('USDARH30','USDARH30P')"
            $convProducts = Invoke-Sqlcmd -Query $addproducts -ServerInstance $Epicdbserver -Database $db 
            foreach($i in $convProducts){$products += $i.productid}
        }

        #clear all products for this users before re-insert
        #$delProducts = "delete from [Rolodex_EntityProducts] where entityid = $EID"
        #Invoke-Sqlcmd -Query $delproducts -ServerInstance $Epicdbserver -Database $db 

        #insert all products back into table for entity
        Foreach($a in $products){
             $plookup = "select * from Rolodex_EntityProducts where entityid = $EID and productID = $a"
             $skip = Invoke-Sqlcmd -Query $plookup -ServerInstance $Epicdbserver -Database $db 
             if($skip.productID.count -ge 1){continue}
             $pinsert = "insert into [Rolodex_EntityProducts] (EntityLenderDatabaseid, Entityid, ProductID)VALUES(1,$EID,$a)"
             invoke-sqlcmd -Query $pinsert -ServerInstance $Epicdbserver -Database $db 
        } #end of product insert loop

        #Entity phone number
        #####################
        $s = "delete from rolodex_entity_phone where entityid = $EID and sequencenumber = 2"
        Invoke-Sqlcmd -ServerInstance $Epicdbserver -Database $db -Query $s        
        $pno = ''
        $pno = $CRM.Phone -replace '-',''
        if($pno -ne ''){
        $phoneinsert = "INSERT INTO [dbo].[rolodex_entity_phone] ([entityid],[extension],[lenderdatabaseid],[overridephone],[phonenumber],[phonetype],[sequencenumber])VALUES($EID,'',1,0,'$pno','Business',2)"
        }
        Invoke-Sqlcmd -Query $phoneinsert -ServerInstance $Epicdbserver -Database $db 
        
        #Contact phone number
        #####################
        $s = "delete from rolodex_contacts_phone where contactid = $CID and sequencenumber = 2"
        Invoke-Sqlcmd -ServerInstance $Epicdbserver -Database $db -Query $s        
        $phoneinsert = "INSERT INTO [dbo].[rolodex_contacts_phone] ([lenderdatabaseid],[entityid],[contactid],[contactlenderdatabaseid],[sequencenumber],[phonetype],[phonenumber],[extension],[overridephone])VALUES(1,$EID,$CID,1,2,'Business','$pno','',0)"
        if($pno -ne ''){
        Invoke-Sqlcmd -Query $phoneinsert -ServerInstance $Epicdbserver -Database $db 
        }
        write-host $phoneinsert
        #create a select loan officer
        #create a select processor
        ################################################################################
        $historyLookup = "select Top 1 * from [$db].[dbo].Rolodex_EntityStatusHistory where EntityID = $EID order by StatusRecordID desc"
        $his = Invoke-Sqlcmd -Query $historyLookup -ServerInstance $Epicdbserver
        write-host $his.count
        if($his.count -eq 0){
            $insertsql11 = "INSERT INTO Rolodex_EntityStatusHistory ([EntityLenderDatabaseID]
               ,[EntityID]
               ,[StatusRecordID]
               ,[DateFirstEntered]
               ,[DateLastModified]
               ,[DateCompleted]
               ,[StatusID]
               ,[UserID])
               VALUES (1,$EID,1,getdate(),getdate(),getdate(),1,21)"
            #write-host $insertsql
            Invoke-Sqlcmd -Query $insertsql11 -ServerInstance $Epicdbserver -Database $db

        }ELSE{write-host "already active"}


        $cliententities = @($EID)
        foreach($x in $cliententities)
        {
        #write-host $x
            $selects = @('Client Loan Officer','Client Processor')  
            foreach($y in $selects)
            {
                #get Category id
                #################################
                $sql8 = "select categoryid from rolodex_contactcategories where categoryname = '$y'"
                $CC = invoke-sqlcmd -Query $sql8 -serverinstance $Epicdbserver -Database $db
                #write-host $sql8


                $sql = "select contactid from rolodex_contacts where entityid = $x and lastname = '[Select $y]'"
                $result = Invoke-sqlcmd -Query $sql -serverinstance $Epicdbserver -Database $db 

                if($result.contactid -eq $null){

                    #get next ContactID
                    ####################################
                    $sql9 = "select top 1 contactid from rolodex_contacts order by contactid desc"
                    $lastID = Invoke-sqlcmd -Query $sql9 -serverinstance $Epicdbserver -Database $db
                    $nextcontactid = $lastID.contactid + 1

                    write-host "make a $y"
                    $sql6 = @"
                            INSERT INTO rolodex_contacts
                                   ([lenderdatabaseid]
                                   ,[entityid]
                                   ,[contactid]
                                   ,[contactlenderdatabaseid]
                                   ,[lastname]
                                   ,[associationdatabaseid]
                                   ,[associationid]
                                   ,[direct_endorsement]
                                   ,[va_automatic]
                                   ,[activeflag]
                                   ,[approval]
                                   ,[expiration]
                                   ,[serverid]
                                   ,[overridezipcode]
                                   ,[RateSheetDeliveryID]
                                   ,[LockConfirmationDeliveryID]
                                   ,[LoanApprovalDeliveryID]
                                   ,[EOIApproved]
                                   ,[EOIExpires]
                                   ,[EOIAmount]
                                   ,[floodserverid]
                                   ,[gsa_date]
                                   ,[gsa_pagenumber]
                                   ,[ldp_date]
                                   ,[ldp_pagenumber]
                                   ,[appraisalserverid]
                                   ,[licensecomparetype]
                                   ,[servermicode]
                                   ,[titleserverid])
                             VALUES
                                   (1,$x,$nextcontactid,1,'[Select $y]',0,0,0,0,1
                                   ,convert(datetime,'1800-01-01 00:00:00.000')
                                   ,convert(datetime,'1800-01-01 00:00:00.000')
                                   ,0,0,0,0,0
                                   ,convert(datetime,'1800-01-01 00:00:00.000')
                                   ,convert(datetime,'1800-01-01 00:00:00.000'),0,0
                                   ,convert(datetime,'1800-01-01 00:00:00.000'),0
                                   ,convert(datetime,'1800-01-01 00:00:00.000'),0,0,1,0,0)
"@
                        invoke-sqlcmd -Query $sql6 -ServerInstance $Epicdbserver -Database $db
                        $sql7 = "INSERT INTO [rolodex_contactcategorylist] (lenderdatabaseid, categoryid, entitylenderdatabaseid, entityid, contactid, contactlenderdatabaseid) VALUES (1,$($CC.categoryid),1,$x,$nextcontactid,1)"
                        invoke-sqlcmd -Query $sql7 -ServerInstance $Epicdbserver -Database $db

                        #Contact Associations
                        switch($y){
                            'Client Loan Officer'{$said = 'Broker'}
                            'Client Processor' {$said = 'Broker/Cor Processor'}
                                   }
                        
                        $assget = "select * from setups_contactassociations where associationalias = '$said'"
                        $assid = Invoke-Sqlcmd -Query $assget -ServerInstance $Epicdbserver -Database $db 
                        $associationid = $assid.associationid

                        $assql = "select * from rolodex_contactassociations where contactid = $nextcontactid and associationid = $associationid" 
                        #write-host $assql

                        $scheck = Invoke-Sqlcmd -Query $assql -ServerInstance $Epicdbserver -Database $db
                        if($scheck.contactid.count -eq 0){
                            $cassosql = "insert into rolodex_contactassociations ([associationdatabaseid],[associationid],[contactid],[contactlenderdatabaseid]) VALUES (1,$associationid,$nextcontactid,1)"
                            Invoke-Sqlcmd -Query $cassosql -ServerInstance $Epicdbserver -Database $db 
                            ################################################################################################################
                        }ELSE{write-host "already has association"}
                }

            }
        }





    }

}
$skipids.Close()
$madeids.Close()