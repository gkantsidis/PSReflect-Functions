function CreateRemoteThread {
    <#
    .SYNOPSIS
    Creates a thread that runs in the virtual address space of another process.

    .DESCRIPTION
    !!! VERY DANGEROUS TO USE !!!

    The CreateRemoteThread function causes a new thread of execution to begin in the address space of the specified process. The thread has access to all objects that the process opens.

    Terminal Services isolates each terminal session by design. Therefore, CreateRemoteThread fails if the target process is in a different session than the calling process.

    The new thread handle is created with full access to the new thread. If a security descriptor is not provided, the handle may be used in any function that requires a thread object handle. When a security descriptor is provided, an access check is performed on all subsequent uses of the handle before access is granted. If the access check denies access, the requesting process cannot use the handle to gain access to the thread.

    If the thread is created in a runnable state (that is, if the CREATE_SUSPENDED flag is not used), the thread can start running before CreateThread returns and, in particular, before the caller receives the handle and identifier of the created thread.

    The thread is created with a thread priority of THREAD_PRIORITY_NORMAL. Use the GetThreadPriority and SetThreadPriority functions to get and set the priority value of a thread.

    When a thread terminates, the thread object attains a signaled state, which satisfies the threads that are waiting for the object.

    The thread object remains in the system until the thread has terminated and all handles to it are closed through a call to CloseHandle.

    The ExitProcess, ExitThread, CreateThread, CreateRemoteThread functions, and a process that is starting (as the result of a CreateProcess call) are serialized between each other within a process. Only one of these events occurs in an address space at a time. This means the following restrictions hold:

    During process startup and DLL initialization routines, new threads can be created, but they do not begin execution until DLL initialization is done for the process.

    Only one thread in a process can be in a DLL initialization or detach routine at a time.

    ExitProcess returns after all threads have completed their DLL initialization or detach routines.

    A common use of this function is to inject a thread into a process that is being debugged to issue a break. However, this use is not recommended, because the extra thread is confusing to the person debugging the application and there are several side effects to using this technique:

    It converts single-threaded applications into multithreaded applications.

    It changes the timing and memory layout of the process.

    It results in a call to the entry point of each DLL in the process.

    Another common use of this function is to inject a thread into a process to query heap or other process information. This can cause the same side effects mentioned in the previous paragraph. Also, the application can deadlock if the thread attempts to obtain ownership of locks that another thread is using.

    .PARAMETER ProcessHandle
    A handle to the process in which the thread is to be created. The handle must have the PROCESS_CREATE_THREAD, PROCESS_QUERY_INFORMATION, PROCESS_VM_OPERATION, PROCESS_VM_WRITE, and PROCESS_VM_READ access rights, and may fail without these rights on certain platforms. For more information, see Process Security and Access Rights.

    .PARAMETER ThreadAttributes
    A pointer to a SECURITY_ATTRIBUTES structure that specifies a security descriptor for the new thread and determines whether child processes can inherit the returned handle. If lpThreadAttributes is NULL, the thread gets a default security descriptor and the handle cannot be inherited. The access control lists (ACL) in the default security descriptor for a thread come from the primary token of the creator.
Windows XP:  The ACLs in the default security descriptor for a thread come from the primary or impersonation token of the creator. This behavior changed with Windows XP with SP2 and Windows Server 2003.

    .PARAMETER StackSize
    The initial size of the stack, in bytes. The system rounds this value to the nearest page. If this parameter is 0 (zero), the new thread uses the default size for the executable. For more information, see Thread Stack Size.

    .PARAMETER EntryPoint
    A pointer to the application-defined function of type LPTHREAD_START_ROUTINE to be executed by the thread and represents the starting address of the thread in the remote process. The function must exist in the remote process. For more information, see ThreadProc.

    .PARAMETER Parameter
    A pointer to a variable to be passed to the thread function.

    .PARAMETER CreationFlags
    The flags that control the creation of the thread.

    .EXAMPLE
    TODO: add an example

    .LINK
    https://msdn.microsoft.com/en-us/library/windows/desktop/ms682437(v=vs.85).aspx

    .NOTES
        (func kernel32 CreateRemoteThread ([IntPtr]) @(
            [IntPtr],               # _In_  HANDLE                 hProcess,
            [IntPtr],               # _In_  LPSECURITY_ATTRIBUTES  lpThreadAttributes,
            [Int32],                # _In_  SIZE_T                 dwStackSize,
            [IntPtr],               # _In_  LPTHREAD_START_ROUTINE lpStartAddress,
            [IntPtr],               # _In_  LPVOID                 lpParameter,
            [UInt32],               # _In_  DWORD                  dwCreationFlags,
            [Int32].MakeByRefType() # _Out_ LPDWORD                lpThreadId
        ) -EntryPoint CreateRemoteThread -SetLastError),
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IntPtr]
        $ProcessHandle,

        [IntPtr]
        $ThreadAttributes = [IntPtr]::Zero,

        [Int32]
        $StackSize = 0,

        [Parameter(Mandatory = $true)]
        [IntPtr]
        $EntryPoint,

        [Parameter(Mandatory = $true)]
        [IntPtr]
        $Parameter,

        [UInt32]
        $CreationFlags = 0
    )

    [Int32]$threadId = 0
    $threadHandle = $kernel32::CreateRemoteThread($ProcessHandle, $ThreadAttributes, $StackSize, $EntryPoint, $Parameter, $CreationFlags, [ref]$threadId)
    $LastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()

    if ($threadHandle -eq [IntPtr]::Zero) {
        $err = [ComponentModel.Win32Exception] $LastError
        throw "CreateRemoteThread Error [$($err.NativeErrorCode)]: $($err.Message)"
    }


    [PSCustomObject]@{
        ThreadHandle = $threadHandle
        ThreadId     = $threadId
    }
}