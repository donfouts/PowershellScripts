$genserver = "phm-db-gensql01"
$gendb ="Bizrules"
$insideserver = "PHM-Wb-SQL-FI02\sqlweb01"
$insideDB = "InsidePlazaHomeMortgage"
$Epicdbserver = "phm-los-pdb01\SQLLOSProd"
$db = "Epic_PROD"

$NewCSVObject = @()
function Release-Ref ($ref) { 
([System.Runtime.InteropServices.Marshal]::ReleaseComObject( 
[System.__ComObject]$ref) -gt 0) 
[System.GC]::Collect() 
[System.GC]::WaitForPendingFinalizers() 
} 


$AEget = "select DataTrac_ID, FirstName, LastName from Users where Branch_ID in (23,14,30,16) and Department_ID = 2 and [status] = 0"
$AEs = Invoke-Sqlcmd -ServerInstance $insideserver -Database $insideDB -Query $AEget

foreach($x in $AEs)
{
    
    if($x.LastName -eq 'House')
    {
        $last = $x.FirstName
    }
    else
    {
    $last = $x.lastname
    }
    $file = "T:\Don\epic\imports\ClientEmailList\AELists\" + $x.Firstname.substring(0,1) + $last + ".xlsx"

    $Excel = New-Object -ComObject Excel.Application
    $Excel.Visible = $True
    $ExcelWorkBook = $Excel.Workbooks.add()
    $ExcelWorkSheet = $Excel.WorkSheets.item(1)
    $ExcelWorkSheet.activate()
    $Excel.Range("A" + 1).Activate()
    $ExcelWorkSheet.Columns.item(1).columnWidth = 10
    $ExcelWorkSheet.Columns.item(2).columnWidth = 10
    $ExcelWorkSheet.Columns.item(3).columnWidth = 12
    $ExcelWorkSheet.Columns.item(4).columnWidth = 50
    $ExcelWorkSheet.Columns.item(5).columnWidth = 50
    $ExcelWorkSheet.Columns.item(6).columnWidth = 50

    $ExcelWorkSheet.Cells.Item(1,1) = 'Client ID'
    $ExcelWorkSheet.Cells.Item(1,1).Interior.ColorIndex = 33
    $ExcelWorkSheet.Cells.Item(1,2) = 'User Name'
    $ExcelWorkSheet.Cells.Item(1,2).Interior.ColorIndex = 33
    $ExcelWorkSheet.Cells.Item(1,3) = 'Password'
    $ExcelWorkSheet.Cells.Item(1,3).Interior.ColorIndex = 33
    $ExcelWorkSheet.Cells.Item(1,4) = 'Contact Email'
    $ExcelWorkSheet.Cells.Item(1,4).Interior.ColorIndex = 33
    $ExcelWorkSheet.Cells.Item(1,5) = 'Company Name'
    $ExcelWorkSheet.Cells.Item(1,5).Interior.ColorIndex = 33
    $ExcelWorkSheet.Cells.Item(1,6) = 'Company Address'
    $ExcelWorkSheet.Cells.Item(1,6).Interior.ColorIndex = 33
    $lastRow = 2

    $getpasswords = "Select * from ClientImport where AE = '$($x.DataTrac_ID)' and skip = 2"
    $clients = Invoke-Sqlcmd -ServerInstance $genserver -Database $gendb -Query $getpasswords
    foreach($c in $clients)
    {
        $ExcelWorkSheet.Cells.Item($lastRow,1) = $c.ID
        $ExcelWorkSheet.Cells.Item($lastRow,2) = 'Admin'
        $ExcelWorkSheet.Cells.Item($lastRow,3) = $c.Password
        $ExcelWorkSheet.Cells.Item($lastRow,4) = $c.Email
        $ExcelWorkSheet.Cells.Item($lastRow,5) = $c.Company
        $ExcelWorkSheet.Cells.Item($lastRow,6) = $c.Addressline1
        $lastRow++
    }
    
    $ExcelWorkBook.SaveAS($file)
    $ExcelWorkBook.Close()
    $a = $Excel.Quit 
 
    $a = Release-Ref($ExcelWorkSheet) 
    $a = Release-Ref($ExcelWorkBook) 
    $a = Release-Ref($Excel) 
    Stop-Process -Name EXCEL -Force

}



