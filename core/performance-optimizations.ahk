SendMode "Input"
SetWorkingDir A_ScriptDir

; ####################################################################
; # PERFORMANCE OPTIMIZATIONS MODULE                                  #
; # Purpose: Memory management, efficient operations, and monitoring    #
; ####################################################################

; ====================================================================
; PERFORMANCE MONITORING
; ====================================================================

global _PerfMetrics := {startTime: A_TickCount, operations: 0, errors: 0}
global _MemoryTracker := {}

; -------------------------------------------------------------------
; Function: StartPerformanceTimer(operation)
; Purpose : Starts timing an operation for performance monitoring
; -------------------------------------------------------------------
StartPerformanceTimer(operation) {
    global _PerfMetrics
    _PerfMetrics[operation] := {start: A_TickCount, active: true}
}

; -------------------------------------------------------------------
; Function: EndPerformanceTimer(operation)
; Purpose : Ends timing and logs performance data
; -------------------------------------------------------------------
EndPerformanceTimer(operation) {
    global _PerfMetrics
    if (_PerfMetrics.HasKey(operation) && _PerfMetrics[operation].active) {
        duration := A_TickCount - _PerfMetrics[operation].start
        _PerfMetrics[operation].duration := duration
        _PerfMetrics[operation].active := false
        _PerfMetrics.operations++

        ; Log slow operations (>2 seconds)
        if (duration > 2000) {
            LogPerformanceIssue(operation, duration)
        }

        return duration
    }
    return 0
}

; -------------------------------------------------------------------
; Function: LogPerformanceIssue(operation, duration)
; Purpose : Logs performance issues for later review
; -------------------------------------------------------------------
LogPerformanceIssue(operation, duration) {
    logFile := A_Temp . "\ahk_performance.log"
    timestamp := A_Now
    logEntry := timestamp . " - SLOW OPERATION: " . operation . " took " . duration . "ms`n"
    FileAppend(logEntry, logFile)
}

; ====================================================================
; ENHANCED TEMPORARY FILE MANAGEMENT
; ====================================================================

global _TempFileRegistry := {}
global _CleanupTimer := 0

; -------------------------------------------------------------------
; Function: CreateManagedTempFile(prefix := "temp_", extension := ".txt", lifetimeMinutes := 30)
; Purpose : Creates temporary file with automatic cleanup tracking
; Returns : Full path to temporary file
; -------------------------------------------------------------------
CreateManagedTempFile(prefix := "temp_", extension := ".txt", lifetimeMinutes := 30) {
    ; Generate unique filename
    timestamp := A_TickCount
    random := Mod(A_Now, 1000)
    filename := prefix . timestamp . "_" . random . extension
    filePath := A_Temp . "\" . filename

    ; Register for cleanup
    _TempFileRegistry[filePath] := {
        created: A_Now,
        lifetime: lifetimeMinutes * 60 * 1000 ; Convert to milliseconds
    }

    ; Start cleanup timer if not already running
    if (_CleanupTimer = 0) {
        SetTimer(CleanupTempFiles, 300000) ; Check every 5 minutes
        _CleanupTimer := 1
    }

    return filePath
}

; -------------------------------------------------------------------
; Function: ManagedFileAppend(filePath, content, encoding := "UTF-8")
; Purpose : Safe file append with error handling and validation
; Returns : true if successful
; -------------------------------------------------------------------
ManagedFileAppend(filePath, content, encoding := "UTF-8") {
    try {
        ; Validate file size limit (10MB)
        if (FileExist(filePath)) {
            FileGetSize(&size, filePath)
            if (size > 10485760) {
                ShowErrorTip("File too large: " . filePath)
                return false
            }
        }

        ; Validate content size
        if (StrLen(content) > 1048576) { ; 1MB per write
            ShowErrorTip("Content too large for single write")
            return false
        }

        FileAppend(content, filePath, encoding)
        return !ErrorLevel
    } catch e {
        ShowErrorTip("File append failed: " . e.message)
        return false
    }
}

; -------------------------------------------------------------------
; Function: ManagedFileRead(filePath, encoding := "UTF-8")
; Purpose : Safe file read with size validation
; Returns : File content or empty string on error
; -------------------------------------------------------------------
ManagedFileRead(filePath, encoding := "UTF-8") {
    try {
        if (!FileExist(filePath)) {
            return ""
        }

        FileGetSize(&size, filePath)
        if (size > 10485760) { ; 10MB limit
            ShowErrorTip("File too large to read: " . filePath)
            return ""
        }

        content := FileRead(filePath, encoding)
        return content
    } catch e {
        ShowErrorTip("File read failed: " . e.message)
        return ""
    }
}

; -------------------------------------------------------------------
; Function: CleanupTempFiles
; Purpose : Timer callback for automatic cleanup of expired temp files
; -------------------------------------------------------------------
CleanupTempFiles() {
    currentTime := A_Now
    expiredFiles := []

    for filePath, info in _TempFileRegistry {
        age := currentTime - info.created
        if (age > info.lifetime) {
            expiredFiles.Push(filePath)
        }
    }

    for index, filePath in expiredFiles {
        try {
            if (FileExist(filePath)) {
                FileDelete(filePath)
            }
            _TempFileRegistry.Delete(filePath)
        } catch e {
            ; Log cleanup failures but continue
        }
    }

    ; Stop timer if no more files to track
    if (_TempFileRegistry.Count() = 0) {
        SetTimer(CleanupTempFiles, 0)
        _CleanupTimer := 0
    }
}

; ====================================================================
; ENHANCED CLIPBOARD OPERATIONS
; ====================================================================

global _ClipboardCache := {}
global _ClipboardHistory := []
global _MaxClipboardHistory := 10

; -------------------------------------------------------------------
; Function: OptimizedClipboardGet()
; Purpose : Efficient clipboard access with caching
; Returns : Clipboard content
; -------------------------------------------------------------------
OptimizedClipboardGet() {
    currentHash := HashClipboard()

    ; Return cached version if unchanged
    if (_ClipboardCache.HasKey("content") && _ClipboardCache.hash = currentHash) {
        return _ClipboardCache.content
    }

    ; Cache current clipboard
    _ClipboardCache.content := Clipboard
    _ClipboardCache.hash := currentHash
    _ClipboardCache.timestamp := A_TickCount

    return _ClipboardCache.content
}

; -------------------------------------------------------------------
; Function: OptimizedClipboardSet(content, addToHistory := true)
; Purpose : Efficient clipboard set with optional history tracking
; Returns : true if successful
; -------------------------------------------------------------------
OptimizedClipboardSet(content, addToHistory := true) {
    try {
        ; Validate content size
        if (StrLen(content) > 1048576) { ; 1MB limit
            ShowErrorTip("Clipboard content too large")
            return false
        }

        ; Add to history if requested
        if (addToHistory && content != _ClipboardCache.content) {
            AddToClipboardHistory(content)
        }

        Clipboard := content
        ClipWait(1)

        if (!ErrorLevel) {
            ; Update cache
            _ClipboardCache.content := content
            _ClipboardCache.hash := HashClipboard()
            _ClipboardCache.timestamp := A_TickCount
            return true
        }
    } catch e {
        ShowErrorTip("Clipboard set failed: " . e.message)
    }

    return false
}

; -------------------------------------------------------------------
; Function: AddToClipboardHistory(content)
; Purpose : Manages clipboard history with size limits
; -------------------------------------------------------------------
AddToClipboardHistory(content) {
    global _ClipboardHistory, _MaxClipboardHistory

    ; Skip duplicates
    for index, item in _ClipboardHistory {
        if (item.content = content) {
            return ; Already in history
        }
    }

    ; Add to beginning of history
    _ClipboardHistory.InsertAt(1, {content: content, timestamp: A_Now})

    ; Maintain size limit
    while (_ClipboardHistory.Count() > _MaxClipboardHistory) {
        _ClipboardHistory.RemoveAt(_ClipboardHistory.Count())
    }
}

; -------------------------------------------------------------------
; Function: HashClipboard()
; Purpose : Creates a simple hash of clipboard content for change detection
; Returns : Hash string
; -------------------------------------------------------------------
HashClipboard() {
    try {
        content := Clipboard
        ; Simple hash - first 50 chars + length
        return SubStr(content, 1, 50) . "|" . StrLen(content)
    } catch {
        return "error"
    }
}

; ====================================================================
; MEMORY MANAGEMENT
; ====================================================================

; -------------------------------------------------------------------
; Function: OptimizeMemoryUsage()
; Purpose : Performs memory optimization tasks
; -------------------------------------------------------------------
OptimizeMemoryUsage() {
    ; Clear clipboard cache if it's too large
    if (_ClipboardCache.HasKey("timestamp")) {
        age := A_TickCount - _ClipboardCache.timestamp
        if (age > 300000) { ; 5 minutes
            _ClipboardCache := {}
        }
    }

    ; Clear expired temp files
    CleanupTempFiles()

    ; Trim clipboard history
    while (_ClipboardHistory.Count() > _MaxClipboardHistory) {
        _ClipboardHistory.RemoveAt(_ClipboardHistory.Count())
    }

    ; Force garbage collection (AHK doesn't have explicit GC, but this helps)
    global _PerfMetrics
    if (_PerfMetrics.operations > 100) {
        _PerfMetrics.operations := 0
        ; Reset metrics to prevent memory growth
    }
}

; ====================================================================
; BATCH OPERATIONS
; ====================================================================

; -------------------------------------------------------------------
; Function: BatchFileOperations(operations*)
; Purpose : Performs multiple file operations efficiently
; Returns : Object with operation results
; -------------------------------------------------------------------
BatchFileOperations(operations*) {
    results := {success: 0, failed: 0, errors: []}

    for index, operation in operations {
        StartPerformanceTimer("batch_op_" . A_Index)

        try {
            if (operation.type = "write") {
                success := ManagedFileAppend(operation.file, operation.content, operation.encoding)
            } else if (operation.type = "read") {
                result := ManagedFileRead(operation.file, operation.encoding)
                success := (result != "")
            } else if (operation.type = "delete") {
                if (FileExist(operation.file)) {
                    FileDelete(operation.file)
                    success := !ErrorLevel
                } else {
                    success := true ; File doesn't exist
                }
            }

            if (success) {
                results.success++
            } else {
                results.failed++
                results.errors.Push("Failed operation: " . operation.type . " on " . operation.file)
            }
        } catch e {
            results.failed++
            results.errors.Push("Exception in operation: " . e.message)
        }

        EndPerformanceTimer("batch_op_" . A_Index)
    }

    return results
}

; ====================================================================
; PERFORMANCE REPORTING
; ====================================================================

; -------------------------------------------------------------------
; Function: GetPerformanceReport()
; Purpose : Returns current performance metrics
; Returns : Object with performance data
; -------------------------------------------------------------------
GetPerformanceReport() {
    global _PerfMetrics, _TempFileRegistry, _ClipboardHistory

    uptime := A_TickCount - _PerfMetrics.startTime
    activeTempFiles := 0

    for filePath, info in _TempFileRegistry {
        age := A_Now - info.created
        if (age < info.lifetime) {
            activeTempFiles++
        }
    }

    return {
        uptimeMs: uptime,
        totalOperations: _PerfMetrics.operations,
        totalErrors: _PerfMetrics.errors,
        activeTempFiles: activeTempFiles,
        clipboardHistorySize: _ClipboardHistory.Count(),
        memoryOptimized: A_TickCount - _PerfMetrics.startTime > 300000
    }
}