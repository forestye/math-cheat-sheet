$ErrorActionPreference = "Stop"

$srcDir = Join-Path $PSScriptRoot "src"
$pdfDir = Join-Path $PSScriptRoot "pdfs"

# 检查源目录是否存在
if (!(Test-Path -Path $srcDir)) {
    Write-Error "Source directory '$srcDir' not found."
    exit 1
}

# 创建输出目录
if (!(Test-Path -Path $pdfDir)) {
    New-Item -ItemType Directory -Path $pdfDir | Out-Null
    Write-Host "Created directory: $pdfDir"
}

# 获取所有 .tex 文件
$texFiles = Get-ChildItem -Path $srcDir -Filter *.tex

if ($texFiles.Count -eq 0) {
    Write-Warning "No .tex files found in '$srcDir'."
    exit
}

# 分离 all-in-one.tex，因为它依赖于其他 PDF 文件
$allInOneFile = $texFiles | Where-Object { $_.Name -eq "all-in-one.tex" }
$standardFiles = $texFiles | Where-Object { $_.Name -ne "all-in-one.tex" }

# 1. 先编译普通文件
foreach ($file in $standardFiles) {
    Write-Host "Compiling $($file.Name)..."
    
    # 执行 xelatex 编译
    # 使用 Start-Process 以便更好地控制参数和等待
    $args = @(
        "-output-directory=$pdfDir",
        "-interaction=nonstopmode",
        "`"$($file.FullName)`""
    )
    
    $process = Start-Process -FilePath "xelatex" -ArgumentList $args -Wait -NoNewWindow -PassThru
    
    if ($process.ExitCode -eq 0) {
        Write-Host "Successfully compiled $($file.Name)" -ForegroundColor Green
    } else {
        Write-Host "Failed to compile $($file.Name). Check log in $pdfDir for details." -ForegroundColor Red
    }
}

# 2. 最后编译 all-in-one.tex
if ($allInOneFile) {
    Write-Host "Compiling $($allInOneFile.Name)..." -ForegroundColor Cyan
    
    # 在 pdfs 目录下运行，以便能找到生成的 PDF 文件
    # 不需要 -output-directory，因为工作目录就是输出目录
    $argsAllInOne = @(
        "-interaction=nonstopmode",
        "`"$($allInOneFile.FullName)`""
    )
    
    $process = Start-Process -FilePath "xelatex" -ArgumentList $argsAllInOne -WorkingDirectory $pdfDir -Wait -NoNewWindow -PassThru
    
    if ($process.ExitCode -eq 0) {
        Write-Host "Successfully compiled $($allInOneFile.Name)" -ForegroundColor Green

        # 移动并重命名为 math-cheat-sheet.pdf 到根目录
        $sourcePdf = Join-Path $pdfDir "all-in-one.pdf"
        $destPdf = Join-Path $PSScriptRoot "math-cheat-sheet.pdf"
        
        if (Test-Path $sourcePdf) {
            Move-Item -Path $sourcePdf -Destination $destPdf -Force
            Write-Host "Generated: $destPdf" -ForegroundColor Green
        }
    } else {
        Write-Host "Failed to compile $($allInOneFile.Name). Check log in $pdfDir for details." -ForegroundColor Red
    }
}

# 清理中间文件
Write-Host "Cleaning up intermediate files..."
$intermediateExtensions = @("*.aux", "*.log", "*.out", "*.toc", "*.synctex.gz", "*.fls", "*.fdb_latexmk", "*.xdv")

foreach ($ext in $intermediateExtensions) {
    Get-ChildItem -Path $pdfDir -Filter $ext | Remove-Item -Force -ErrorAction SilentlyContinue
}

Write-Host "All tasks completed." -ForegroundColor Cyan
