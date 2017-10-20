$Epicdbserver = "phm-los-pdb01\sqllosProd"
$db = "Epic_Prod"


$entsql = "select * from rolodex_contacts where contactid in (select contactid from rolodex_contactcategorylist where categoryid = (select categoryid FROM rolodex_contactcategories where categoryname = 'Underwriter'))"
$entities = Invoke-Sqlcmd -query $entsql -serverinstance $epicdbserver -Database $db

foreach($e in $entities){
    write-host $e.firstname
    #UW Level
    #####################
    $DTsql = "select NewLevel from custom_UWlevel where firstname = '$($e.firstname)' and lastname = '$($e.lastname)'"
    $DTinfo = Invoke-Sqlcmd -Query $DTsql -ServerInstance phm-los-ddb01 -database Epic_Dev
    $updatesql = "UPDATE [rolodex_contacts] SET [creditlifeid] = '$($DTinfo.NewLevel)' where contactid = $($e.contactid)"
    Invoke-Sqlcmd -Query $updatesql -ServerInstance $Epicdbserver -Database $db
    #Appraisal Reviewer
    ######################
    $csql = "select * from rolodex_contactcategorylist where contactid = $($e.contactid) and categoryid = 92"
    $check = Invoke-Sqlcmd -Query $csql -ServerInstance $Epicdbserver -Database $db
    if($check.categoryid.count -eq 0)
    {
        write-host "adding into apprasial review"
        $insertSQL = "INSERT INTO Rolodex_contactcategorylist ([lenderdatabaseid],[categoryid],[entitylenderdatabaseid],[entityid],[contactid],[contactlenderdatabaseid]) VALUES (1,92,1,$($e.entityid),$($e.contactid),1)"
        Invoke-Sqlcmd -Query $insertSQL -ServerInstance $Epicdbserver -Database $db
    }


    

}