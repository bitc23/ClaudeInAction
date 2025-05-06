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
                
                $vmName = "N/A"
                $dsName = "N/A"
                
                if ($entity.Type -eq "VirtualMachine") {
                    $vmView = Get-View $entity
                    $vmName = $vmView.Name
                }
                
                # Check if task description contains datastore info
                if ($task.Description -match "datastore") {
                    $dsPattern = "'\[(.*?)\]'"
                    if ($task.Description -match $dsPattern) {
                        $dsName = $matches[1]
                    }
                }
                
                # Get detailed task info
                $taskView = Get-View $task.Id
                $taskDetails = "N/A"
                
                # Attempt to get more detailed information based on the task type
                if ($taskView.Info.Reason) {
                    $taskDetails = $taskView.Info.Reason.GetType().Name
                }
                
                if ($taskView.Info.Key) {
                    $taskDetails = $taskView.Info.Key
                }
                
                # Try to get affected objects
                $target = "N/A"
                if ($taskView.Info.EntityName) {
                    $target = $taskView.Info.EntityName
                }
                
                [PSCustomObject]@{
                    Name = $task.Name
                    Details = $taskView.Info.DescriptionId
                    State = $task.State
                    Target = $target
                    PercentComplete = $task.PercentComplete
                    VM = $vmName
                    Datastore = $dsName
                    StartTime = $task.StartTime
                    RunTime = [math]::Round(((Get-Date) - $task.StartTime).TotalMinutes, 2)
                }
            }
            
            $enhancedTasks | Sort-Object -Property StartTime | Format-Table -AutoSize -Property Name, Details, State, Target, PercentComplete, VM, Datastore, StartTime, RunTime
        } else {
            Write-Host "No running tasks found." -ForegroundColor Yellow
        }
        
        Write-Host "Refreshing in 10 seconds... Press Ctrl+C to exit." -ForegroundColor Cyan
        Start-Sleep -Seconds 10
    }
}

Show-EnhancedTasks