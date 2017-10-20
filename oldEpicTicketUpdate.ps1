function Release-Ref ($ref) { 
([System.Runtime.InteropServices.Marshal]::ReleaseComObject( 
[System.__ComObject]$ref) -gt 0) 
[System.GC]::Collect() 
[System.GC]::WaitForPendingFinalizers() 
} 

$Excel = New-Object -ComObject Excel.Application
$Excel.Visible = $True
$ExcelWorkBook = $Excel.Workbooks.Open("Y:\Project X\DeploymentLog.xlsx")
$ExcelWorkSheet = $Excel.WorkSheets.item(1)
$ExcelWorkSheet.activate()

$lastRow = $ExcelWorkSheet.UsedRange.rows.count + 1
$Excel.Range("A" + $lastrow).Activate()


$whereto = read-host 'Target- 1:DEV, 2:UAT, 3:PROD, 4:TRAIN'
switch($whereto)
    {
        1{
            $loc = 'Dev'
            $Keyword = 'QA'
         }
        2{
            $loc = 'UAT'
            $Keyword = 'UAT'
         }
        3{
            $loc = 'PROD'
            $Keyword = 'Done'
         }

    }

$Date = Get-Date -Format g
set-location D:\Repositories\PHM_Epic

$query = "SELECT [System.Id],[Title], [Assigned to] FROM WorkItems WHERE [System.State] = 'deploy to $loc' " 

$Tickets = tfpt query /wiql:$query /include:data

$info = @()

foreach($x in $Tickets)
{
    $array = $x -split "`t"
    $hashtbl = @{Ticket = $array[0]; Title = $array[1]; User = $array[2]}
    $info += $hashtbl
}
write-host "tickets that were deployed"

foreach($y in $info)
{
    $y.Ticket
}


$title = "Update Ticket(s)"
$message = "Do you want to proceed?"

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Update all tickets in VSO and Send out movement email."

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Aborts Script"

$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$result = $host.ui.PromptForChoice($title, $message, $options, 0) 

switch ($result)
    {
        0 {"Lets do this!"}
        1 {exit}
    }

$images = @{image1 = 'D:\DfoutsCode\Devops\images\image1.jpg'} 
$html = @'
<style type = "test/css">
.ExternalClass{
    width:100%;
}

.ExternalClass,
.ExternalClass p,
.ExternalClass span,
.ExternalClass font,
.ExternalClass td,
.ExternalClass div{
    line-height: 100%;
}
</style>
'@
$html = $html + "<div style='width:32%;float:left;'><img src='cid:image1'></img></div>	<div style='width:32%;float:left;'></p>$date</p></div><h1>The following tickets have been deployed to $loc</h1>"


foreach($i in $info){


#add ticket to Email message
$html = $html + "<div style='width:80%;min-height:1em;margin:10px auto;border-style:solid;border-width:2px;border-color:#D0651D;background-color:white;padding:5px;'>"
$html = $html + "<div style='width:10%;Float:left;'><a href='https://plazahomemortgage.visualstudio.com/Epic/_workitems?id=$($i.Ticket)'>$($i.Ticket)</a></div>"
$html = $html + "<div style='width:50%;Float:left;'>$($i.Title)</div>"
$html = $html + "<div style='width:15%;Float:right;'>$($i.User)</div>"
$html = $html + "</div>"

$SRP = $i.Ticket
2
#set string for History entry
    $History = "History=$($i.Ticket) was deployed to $loc on $Date"
#set string for Location
    $Location = "State=$Keyword"

    $update = "$Location;$History"
    Write-host "The Ticket: $SRP will be updated in VSO to be in $Keyword"
    #write-host $update

    & "tfpt.exe" "workitem" "/update" "$SRP" "/fields:$update"

    $ExcelWorkSheet.Cells.Item($lastRow,1) = $Date
    $ExcelWorkSheet.Cells.Item($lastRow,2) = $i.Ticket
    $ExcelWorkSheet.Cells.Item($lastRow,3) = $i.Title
    $ExcelWorkSheet.Cells.Item($lastRow,4) = " - Description - "
    $ExcelWorkSheet.Cells.Item($lastRow,5) = $i.User
    $ExcelWorkSheet.Cells.Item($lastRow,6) = $loc
    
    $ExcelWorkSheet.Hyperlinks.Add(
        $ExcelWorkSheet.Cells.Item($lastRow,2),
        "https://plazahomemortgage.visualstudio.com",
        "/Epic/_workitems?id=$($i.Ticket)",
        "Open in VSO",
        $ExcelWorkSheet.Cells.Item($lastRow,2).Text
    ) | Out-Null
    
    $lastRow++

}

$html = $html + "<p>There is a Deployment log you can find in the <a href='File://///Phm-fs-shared01\shared\Project X\DeploymentLog.xlsx'>Project X folder</a></p>"

$params = @{ 
    InlineAttachments = $images 
    Body = $html 
    BodyAsHtml = $true 
    Subject = "$loc Deployment" 
    From = 'Don.fouts@Plazahomemortgage.com' 
    To = 'epicteam@PlazaHomeMortgage.Com' 
    SmtpServer = 'outlook.pacific.corp.com' 
    Credential = (Get-Credential don.fouts) 
} 
 
. D:\DfoutsCode\Devops\Send-MailMessage.ps1 

Send-MailMessage @params

$ExcelWorkBook.Save()
$ExcelWorkBook.Close()
$a = $Excel.Quit 
 
$a = Release-Ref($ExcelWorkSheet) 
$a = Release-Ref($ExcelWorkBook) 
$a = Release-Ref($Excel) 
Stop-Process -Name EXCEL -Force