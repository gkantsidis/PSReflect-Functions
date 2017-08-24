function GetModuleBaseName {
    <#
    .SYNOPSIS
    Retrieves the base name of the specified module.

    .DESCRIPTION
    The GetModuleBaseName function is primarily designed for use by debuggers and similar applications that must extract module information from another process.
    If the module list in the target process is corrupted or is not yet initialized, or if the module list changes during the function call as a result of DLLs being loaded or unloaded,
    GetModuleBaseName may fail or return incorrect information.

    .PARAMETER ProcessHandle
    A handle to the process that contains the module.
    The handle must have the PROCESS_QUERY_INFORMATION and PROCESS_VM_READ access rights. For more information, see Process Security and Access Rights.

    .PARAMETER ModuleHandle
    A handle to the module. If this parameter is NULL, this function returns the name of the file used to create the calling process.

    .EXAMPLE
        $proc = (Get-Process -Name notepad*)[0]
        $nph = OpenProcess -ProcessId $proc.Id -DesiredAccess PROCESS_QUERY_INFORMATION,PROCESS_VM_READ -InheritHandle $false
        EnumProcessModules -ProcessHandle $nph |% { GetModuleBaseName $nph $_ }
        CloseHandle $nph

    .NOTES

    (func psapi GetModuleBaseName ([UInt32]) @(
        [IntPtr],                    # _In_     HANDLE  hProcess,
        [IntPtr],                    # _In_opt_ HMODULE hModule,
        [System.Text.StringBuilder], # _Out_    LPTSTR  lpBaseName,
        [UInt32]                     #_In_     DWORD   nSize
    ) -EntryPoint GetModuleBaseName -SetLastError)

    .LINK
    https://msdn.microsoft.com/en-us/library/windows/desktop/ms683196(v=vs.85).aspx
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IntPtr]
        $ProcessHandle,

        [Parameter(Mandatory = $true)]
        [IntPtr]
        $ModuleHandle
    )

    $capacity = 2048
    $sb = New-Object -TypeName System.Text.StringBuilder($capacity)

    [UInt32]$length = $psapi::GetModuleBaseName($ProcessHandle, $ModuleHandle, $sb, $capacity)
    $LastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

    if ($length -eq 0) {
        Write-Error "GetModuleBaseName Error: $(([ComponentModel.Win32Exception] $LastError).Message)"
    }

    Write-Output $sb.ToString()
}