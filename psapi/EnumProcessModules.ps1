function EnumProcessModules
{
    <#
    .SYNOPSIS
    Retrieves a handle for each module in the specified process.

    .DESCRIPTION
    The EnumProcessModules function is primarily designed for use by debuggers and similar applications that must extract module information from another process.
    If the module list in the target process is corrupted or not yet initialized, or if the module list changes during the function call as a result of DLLs being loaded or unloaded,
    EnumProcessModules may fail or return incorrect information.

    If this function is called from a 32-bit application running on WOW64, it can only enumerate the modules of a 32-bit process.
    If the process is a 64-bit process, this function fails and the last error code is ERROR_PARTIAL_COPY (299).

    .PARAMETER ProcessHandle
    A handle to the process.

    .EXAMPLE
    An example
      $proc = (Get-Process -Name notepad*)[0]
      $nph = OpenProcess -ProcessId $proc.Id -DesiredAccess PROCESS_QUERY_INFORMATION,PROCESS_VM_READ -InheritHandle $false
      EnumProcessModules -ProcessHandle $nph
      CloseHandle $nph


    .NOTES

        (func psapi EnumProcessModules ([bool]) @(
        [IntPtr],                 # _In_  HANDLE  hProcess,
        [IntPtr],                 # _Out_ HMODULE *lphModule,
        [UInt32],                 # _In_  DWORD   cb,
        [Int32].MakeByRefType()   # _Out_ LPDWORD lpcbNeeded
    ) -EntryPoint EnumProcessModules -SetLastError)

    .LINK

    https://msdn.microsoft.com/en-us/library/windows/desktop/ms682631(v=vs.85).aspx.

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IntPtr]
        $ProcessHandle
    )

    $number_of_bytes_required = 0

    $cb = 8192
    $module = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($cb)

    Write-Debug -Message "Inside EnumProcessModules ($module)"
    [bool]$success = $psapi::EnumProcessModules($ProcessHandle, $module, $cb, [ref]$number_of_bytes_required)
    Write-Debug -Message "After EnumProcessModules call"
    $LastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

    if(-not $success)
    {
        Write-Debug -Message "Error in calling EnumProcessModules"
        [System.Runtime.InteropServices.Marshal]::FreeHGlobal($module)
        $err = [ComponentModel.Win32Exception] $LastError
        throw "EnumProcessModules Error [$($err.NativeErrorCode)]: $($err.Message)"
    }

    if ($number_of_bytes_required -gt $cb)
    {
        Write-Debug -Message "Size is small "

        [System.Runtime.InteropServices.Marshal]::FreeHGlobal($module)
        $cb = 2*$number_of_bytes_required
        $module = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($cb)

        $success = $psapi::EnumProcessModules($ProcessHandle, $module, $cb, [ref]$number_of_bytes_required)
        $LastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

        if(-not $success)
        {
            [System.Runtime.InteropServices.Marshal]::FreeHGlobal($module)
            throw "EnumProcessModules Error: $(([ComponentModel.Win32Exception] $LastError).Message)"
        }
    }

    $pointer_size = [IntPtr]::Size
    $entries = $number_of_bytes_required / $pointer_size
    Write-Verbose -Message "Number of modules = $entries"

    $result = New-Object -TypeName 'IntPtr[]' -ArgumentList $entries
    for ($i = 0; $i -lt $entries; $i++) {
        $modulePtr = [System.Runtime.InteropServices.Marshal]::ReadIntPtr($module, $i * $pointer_size)
        $result[$i] = $modulePtr
    }

    [System.Runtime.InteropServices.Marshal]::FreeHGlobal($module)

    Write-Output $result
}