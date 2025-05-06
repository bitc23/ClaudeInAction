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
                
                # Get detailed properties from the task
                $taskDetails = ($task | Get-Member -MemberType Property | 
                               Where-Object { $_.Name -eq "Result" } | 
                               ForEach-Object { $task.($_.Name) }) -join ", "
                
                # If no result, get the object being operated on
                if ([string]::IsNullOrEmpty($taskDetails)) {
                    $taskDetails = $task.ObjectId
                }
                
                # If still no details, use the name of the operation
                if ([string]::IsNullOrEmpty($taskDetails)) {
                    $taskDetails = $task.Name
                }
                
                # Try to get affected objects
                $target = "N/A"
                if ($task.ExtensionData.Info.EntityName) {
                    $target = $task.ExtensionData.Info.EntityName
                }
                
                [PSCustomObject]@{
                    Name = $task.Name
                    Details = $task.ObjectId
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