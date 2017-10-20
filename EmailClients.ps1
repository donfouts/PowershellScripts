$AE = ''

$clientid = 123546
$clientname = 'Fouts Mortgage Corp'
$to = 'don.fouts@gmail.com'
$name = "Don Fouts"
$p = get-date
$l = -join ((65..90) + (97..122) | Get-Random -Count 5 | % {[char]$_})
$Cpassword = "$($p.millisecond)$l!"
$username = "pacific\don.fouts"
$password = cat D:\DfoutsCode\Rolodex\ClientEmail\secure.txt | ConvertTo-SecureString
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password

$html = "D:\DfoutsCode\Rolodex\ClientEmail\clienthtml.html"
$newhtml = "D:\DfoutsCode\Rolodex\ClientEmail\$AE\$clientid.html"
cp $html $newhtml

$images = @{
    image2 = 'D:\DfoutsCode\Rolodex\ClientEmail\clienthtml_files\image002.jpg'
    image4 = 'D:\DfoutsCode\Rolodex\ClientEmail\clienthtml_files\image004.png'
    image9 = 'D:\DfoutsCode\Rolodex\ClientEmail\clienthtml_files\image009.jpg'
    image5 = 'D:\DfoutsCode\Rolodex\ClientEmail\clienthtml_files\image005.png'
    image6 = 'D:\DfoutsCode\Rolodex\ClientEmail\clienthtml_files\image006.png'
    image7 = 'D:\DfoutsCode\Rolodex\ClientEmail\clienthtml_files\image007.png'
    } 

(Get-Content $newhtml) | Foreach-Object { $_ -replace "@CLIENTNAME@", "$clientname" } |
Foreach-Object { $_ -replace "@NAME@", "$name" } |
Foreach-Object { $_ -replace "@CEMAIL@", "$to" } | 
Foreach-Object { $_ -replace "@BID@", "$clientid" } |
Foreach-Object { $_ -replace "@PASS@", "$Cpassword" } |

Set-Content $newhtml

[string]$body = Get-Content $newhtml

$params = @{ 
    InlineAttachments = $images 
    Body = $body 
    BodyAsHtml = $true 
    Subject = "$clientname #$clientid" 
    From = 'don.fouts@plazahomemortgage.com' 
    To = $to 
    SmtpServer = 'outlook.pacific.corp.com' 
    Credential = $cred 
} 


. D:\DfoutsCode\Devops\Send-MailMessage.ps1 

Send-MailMessage @params
