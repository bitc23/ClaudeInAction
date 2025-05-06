function Show-EnhancedTasks {
    while ($true) {
        Clear-Host
        $tasks = Get-Task | Where-Object { $_.State -eq "Running" }
        $taskCount = $tasks.Count
        
        # Count queued tasks (less than 13% complete)
        $queuedTasks = $tasks | Where-Object { $_.PercentComplete -lt 13 }
        $queuedCount = $queuedTasks.Count
        
        # Calculate active tasks (total minus queued)
        $activeCount = $taskCount - $queuedCount
        
        Write-Host "Total Running Tasks: $taskCount" -ForegroundColor Green
        Write-Host "Queued Tasks (<13%): $queuedCount" -ForegroundColor Yellow
        Write-Host "Active Tasks: $activeCount" -ForegroundColor Cyan
        Write-Host ""
        
        if ($taskCount -gt 0) {
            $enhancedTasks = $tasks | ForEach-Object {
                $task = $_
                $entity = $task.ExtensionData.Info.Entity
                
                $vmName = "N/A"
                $dsName = "N/A"
                
                if ($entity.Type -eq "VirtualMachine") {
                    try {
                        $vm = Get-VM -Id $entity.Value -ErrorAction SilentlyContinue
                        if ($vm) {
                            $vmName = $vm.Name
                            # Get the datastores for this VM
                            $vmDatastores = $vm | Get-Datastore -ErrorAction SilentlyContinue
                            if ($vmDatastores) {
                                $dsName = ($vmDatastores | Select-Object -First 1).Name
                                
                                # If more than one datastore, indicate this
                                if ($vmDatastores.Count -gt 1) {
                                    $dsName += " + $($vmDatastores.Count - 1) more"
                                }
                            }
                        } else {
                            # Fallback to Get-View if Get-VM fails
                            $vmView = Get-View $entity -ErrorAction SilentlyContinue
                            if ($vmView) {
                                $vmName = $vmView.Name
                            }
                        }
                    } catch {
                        # Fallback if an error occurs
                        try {
                            $vmView = Get-View $entity -ErrorAction SilentlyContinue
                            if ($vmView) {
                                $vmName = $vmView.Name
                            }
                        } catch {}
                    }
                }
                
                [PSCustomObject]@{
                    Name = $task.Name
                    PercentComplete = $task.PercentComplete
                    VM = $vmName
                    Datastore = $dsName
                    StartTime = $task.StartTime
                    RunTime = [math]::Round(((Get-Date) - $task.StartTime).TotalMinutes, 2)
                }
            }
            
            $enhancedTasks | Sort-Object -Property StartTime | Format-Table -AutoSize -Property Name, PercentComplete, VM, Datastore, StartTime, RunTime
        } else {
            Write-Host "No running tasks found." -ForegroundColor Yellow
        }
        
        Write-Host "Refreshing in 10 seconds... Press Ctrl+C to exit." -ForegroundColor Cyan
        Start-Sleep -Seconds 10
    }
}

Show-EnhancedTasks