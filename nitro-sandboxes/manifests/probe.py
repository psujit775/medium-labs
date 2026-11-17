# What can this container see of the kernel, and which kernel-level calls work?
import ctypes, errno, os, platform
libc = ctypes.CDLL(None, use_errno=True)
print(f"uname -r      : {platform.release()}")
print(f"/proc/version : {open('/proc/version').read().strip()[:80]}")
print(f"cpu model     : {[l for l in open('/proc/cpuinfo') if l.startswith('model name')][0].split(':')[1].strip()[:60]}")
# x86_64 syscall numbers; arguments are harmless or invalid on purpose.
calls = [
    ("getpid", 39, ()),
    ("unshare(CLONE_NEWUSER)", 272, (0x10000000,)),
    ("syslog (read dmesg)", 103, (3, ctypes.create_string_buffer(256), 256)),
    ("mount tmpfs", 165, (b"none", b"/tmp", b"tmpfs", 0, None)),
    ("bpf", 321, (0, None, 0)),
    ("perf_event_open", 298, (None, 0, -1, -1, 0)),
    ("io_uring_setup", 425, (1, ctypes.create_string_buffer(120))),
    ("userfaultfd", 323, (0,)),
    ("keyctl", 250, (0, 0)),
    ("kexec_load", 246, (0, 0, None, 0)),
    ("init_module", 175, (None, 0, b"")),
]
for name, nr, args in calls:
    ctypes.set_errno(0)
    r = libc.syscall(nr, *args)
    e = ctypes.get_errno()
    res = "OK" if r >= 0 else f"{errno.errorcode.get(e, e)} ({os.strerror(e)})"
    print(f"{name:24s}: {res}")
