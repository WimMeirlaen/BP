$ErrorActionPreference = 'Stop'

$bpDir    = "c:\Users\Wim.Meirlaen\OneDrive - E.S.C. BV\Documents\BP\latex-hogent-bachproef\bachproef"
$outDir   = "C:\tmp\bpout"
$finalOutputDir = "c:\Users\Wim.Meirlaen\OneDrive - E.S.C. BV\Documents\BP\latex-hogent-bachproef\output"
$mainTex  = "MeirlaenWimBP.tex"
$miktex   = "C:\Users\Wim.Meirlaen\AppData\Local\Programs\MiKTeX\miktex\bin\x64"
$pythonDir = "C:\Users\Wim.Meirlaen\AppData\Local\Programs\Python\Python312"
$pythonScriptsDir = Join-Path $pythonDir "Scripts"

# Required for minted v3 with MiKTeX and -output-directory
$env:PATH = "$pythonDir;$pythonScriptsDir;$miktex;$env:PATH"
$env:TEXMF_OUTPUT_DIRECTORY = $outDir

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

Push-Location $bpDir

$xelatex  = Join-Path $miktex "xelatex.exe"
$biber    = Join-Path $miktex "biber.exe"

$xeArgs = @(
    "-file-line-error",
    "-interaction=nonstopmode",
    "-output-directory=$outDir",
    "-shell-escape",
    "-synctex=1",
    $mainTex
)

Write-Host "=== Pass 1: xelatex ===" -ForegroundColor Cyan
& $xelatex @xeArgs
Write-Host "=== biber ===" -ForegroundColor Cyan
& $biber --input-directory "$outDir" --output-directory "$outDir" "MeirlaenWimBP"
Write-Host "=== Pass 2: xelatex ===" -ForegroundColor Cyan
& $xelatex @xeArgs
Write-Host "=== Pass 3: xelatex ===" -ForegroundColor Cyan
& $xelatex @xeArgs

Pop-Location
Write-Host "=== Done! PDF: $outDir\MeirlaenWimBP.pdf ===" -ForegroundColor Green

$pdfPath = Join-Path $outDir "MeirlaenWimBP.pdf"
if (Test-Path $pdfPath) {
    New-Item -ItemType Directory -Force -Path $finalOutputDir | Out-Null
    Copy-Item $pdfPath (Join-Path $finalOutputDir "MeirlaenWimBP.pdf") -Force
    Write-Host "=== Copied to: $finalOutputDir\MeirlaenWimBP.pdf ===" -ForegroundColor Green
}
