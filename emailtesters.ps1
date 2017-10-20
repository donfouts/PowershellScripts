$images = @{image1 = 'D:\DfoutsCode\Devops\images\image1.jpg'}  
  
$body = @' 
<html>  
  <body>  
    <img src="cid:image1"><br> 
    <p>testing</p>
  </body>  
</html>  
'@  
  
$params = @{ 
    InlineAttachments = $images 
    Body = $body 
    BodyAsHtml = $true 
    Subject = 'Test email' 
    From = 'Don.fouts@Plazahomemortgage.com' 
    To = 'Plaza.LOS@PlazaHomeMortgage.Com' 
    SmtpServer = 'outlook.pacific.corp.com' 
    Credential = (Get-Credential don.fouts) 
} 
 
. D:\DfoutsCode\Devops\Send-MailMessage.ps1 

Send-MailMessage @params
