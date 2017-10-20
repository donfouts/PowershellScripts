

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

if($Loc -eq 'Prod'){$to = @("EpicTeam@plazahomemortgage.com","PlazaOrd@PointivityASP.com")}
ELSE{$to = @("EpicTeam@plazahomemortgage.com","Epic$($Loc)_Testing@plazahomemortgage.com")}


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


$title = "Email Ticket(s)"
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
$html = $html + "<div style='width:32%;float:left;'><img src='cid:image1'></img></div>	<div style='width:32%;float:left;'></p>$date</p></div><h1>The following updates are queued to deploy into $loc</h1><p>Please log out of the Breeze and Destiny to preserve your work, I will notify everyone when the system is back online.  All PHM tickets that have been intergrated into this update are listed below so we know what is going into $loc.</p>"


foreach($i in $info){


#add ticket to Email message
$html = $html + "<div style='width:80%;min-height:1em;margin:10px auto;border-style:solid;border-width:2px;border-color:#D0651D;background-color:white;padding:5px;'>"
$html = $html + "<div style='width:10%;Float:left;'><a href='https://plazahomemortgage.visualstudio.com/Epic/_workitems?id=$($i.Ticket)'>$($i.Ticket)</a></div>"
$html = $html + "<div style='width:50%;Float:left;'>$($i.Title)</div>"
$html = $html + "<div style='width:15%;Float:right;'>$($i.User)</div>"
$html = $html + "</div>"

$SRP = $i.Ticket

}

$username = "pacific\don.fouts"
$password = cat D:\DfoutsCode\Rolodex\ClientEmail\secure.txt | ConvertTo-SecureString
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password

$params = @{ 
    InlineAttachments = $images 
    Body = $html 
    BodyAsHtml = $true 
    Subject = "$loc Deployment" 
    From = 'Don.fouts@Plazahomemortgage.com' 
    To = $to 
    SmtpServer = 'outlook.pacific.corp.com' 
    Credential = $cred 
} 
 
. D:\DfoutsCode\Devops\Send-MailMessage.ps1 

Send-MailMessage @params