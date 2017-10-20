Function ConvertTo-PDF
{
    <#
    .SYNOPSIS
        Converts HTML strings to pdf files.
    .DESCRIPTION
        Converts HTML strings to pdf files.
    .PARAMETER HTML
        HTML to convert to pdf format.
    .PARAMETER ReportName
        File name to create as a pdf.

    .EXAMPLE
        $html = 'test'
        try 
        {
            ConvertTo-PDF -HTML $html -FileName 'test.pdf' #-ErrorAction SilentlyContinue) 
            Write-Output 'HTML converted to PDF file test.pdf'
        } 
        catch
        {
            Write-Output 'Something bad happened! :('
        }

        Description:
        ------------------
        Create a pdf file with the content of 'test' if the pdf creation dll is available.

    .NOTES
        Requires   : NReco.PdfGenerator.dll (http://pdfgenerator.codeplex.com/)
        Version    : 1.0 03/07/2014
                     - Initial release
        Author     : Zachary Loeber

        Disclaimer : This script is provided AS IS without warranty of any kind. I 
                     disclaim all implied warranties including, without limitation,
                     any implied warranties of merchantability or of fitness for a 
                     particular purpose. The entire risk arising out of the use or
                     performance of the sample scripts and documentation remains
                     with you. In no event shall I be liable for any damages 
                     whatsoever (including, without limitation, damages for loss of 
                     business profits, business interruption, loss of business 
                     information, or other pecuniary loss) arising out of the use of or 
                     inability to use the script or documentation. 

        Copyright  : I believe in sharing knowledge, so this script and its use is 
                     subject to : http://creativecommons.org/licenses/by-sa/3.0/
    .LINK
        http://www.the-little-things.net/

    .LINK
        http://nl.linkedin.com/in/zloeber
    #>
    [CmdletBinding()]
    param
    (
        [Parameter( HelpMessage="Report body, in HTML format.", 
                    ValueFromPipeline=$true )]
        [string]
        $HTML,
        [Parameter( HelpMessage="Report filename to create." )]
        [string]
        $FileName
    )
    BEGIN
    {
        $DllLoaded = $false
        $PdfGenerator = "$((Get-Location).Path)\NReco.PdfGenerator.dll"
        if (Test-Path $PdfGenerator)
        {
            try
            {
                $Assembly = [Reflection.Assembly]::LoadFrom($PdfGenerator)
                $PdfCreator = New-Object NReco.PdfGenerator.HtmlToPdfConverter
                $DllLoaded = $true
            }
            catch
            {
                Write-Error ('ConvertTo-PDF: Issue loading or using NReco.PdfGenerator.dll: {0}' -f $_.Exception.Message)
            }
        }
        else
        {
            Write-Error ('ConvertTo-PDF: NReco.PdfGenerator.dll was not found.')
        }
    }
    PROCESS
    {
        if ($DllLoaded)
        {
            $ReportOutput = $PdfCreator.GeneratePdf([string]$HTML)
            Add-Content -Value $ReportOutput -Encoding byte -Path $FileName
        }
        else
        {
            Throw 'Error Occurred'
        }
    }
    END
    {}
}

$html = 'D:\DfoutsCode\xml2pdf\output.html'

try 
{
    ConvertTo-PDF -HTML $html -FileName 'test.pdf' #-ErrorAction SilentlyContinue) 
    Write-Output 'HTML converted to PDF file test.pdf'
} 
catch
{
    Write-Output 'Something bad happened! :('
}