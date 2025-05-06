function Show-EnhancedTasks {
    while ($true) {
        Clear-Host
        $tasks = Get-Task | Where-Object { $_.State -eq "Running" }
        $taskCount = $tasks.Count
        
        Write-Host "Total Running Tasks: $taskCount" -ForegroundColor Green
        Write-Host ""
        
        if ($taskCount -gt 0) {
            $enhancedTasks = $tasks | ForEach-Object {
                $task = $_
                $entity = $task.ExtensionData.Info.Entity
                $details = $task.ExtensionData.Info.DescriptionId
                
                $vmName = "N/A"
                $dsName = "N/A"
                
                if ($entity.Type -eq "VirtualMachine") {
                    $vmName = (Get-View $entity).Name
                }
                
                # Check if task description contains datastore info
                if ($task.Description -match "datastore") {
                    $dsPattern = "'\[(.*?)\]'"
                    if ($task.Description -match $dsPattern) {
                        $dsName = $matches[1]
                    }
                }
                
                # Get additional task details from ExtensionData
                $detailsText = if ($details) {
                    $details
                } else {
                    $task.ExtensionData.Info.Name
                }
                
                # Try to get target object info
                $target = "N/A"
                if ($task.ExtensionData.Info.EntityName) {
                    $target = $task.ExtensionData.Info.EntityName
                }
                
                [PSCustomObject]@{
                    Name = $task.Name
                    Details = $detailsText
                    Target = $target
                    PercentComplete = $task.PercentComplete
                    VM = $vmName
                    Datastore = $dsName
                    StartTime = $task.StartTime
                    RunTime = [math]::Round(((Get-Date) - $task.StartTime).TotalMinutes, 2)
                }
            }
            
            $enhancedTasks | Sort-Object -Property StartTime | Format-Table -AutoSize -Property Name, Details, Target, PercentComplete, VM, Datastore, StartTime, RunTime
        } else {
            Write-Host "No running tasks found." -ForegroundColor Yellow
        }
        
        Write-Host "Refreshing in 10 seconds... Press Ctrl+C to exit." -ForegroundColor Cyan
        Start-Sleep -Seconds 10
    }
}

Show-EnhancedTasks