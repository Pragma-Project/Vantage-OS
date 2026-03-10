<img width="530" height="530" alt="Final Edited" src="https://github.com/user-attachments/assets/7a67bf54-be76-4814-8049-89a40f53d450" />

*Last Update: 3-9-26* --- 
*Project Start: 3-6-26*

**Basic overview**

A configurable kernel that loads Linux filesystem, drivers, and memory management. However, the true master OS sits above Linux and allows easier configurability (more on that below). The kernel may also be changed in various ways which will be logged in this project's documentation. The OS makes data workloads a core target both in performance and UI - not treating it as just another part of general purpose computing.


**Linux as the base but not the bulk**

Every alternative OS in history has faced the same wall: hardware compatibility. Linux has thousands of engineers and decades of work behind its driver ecosystem. Instead of reimplementing all of that or accepting a fraction of hardware support, Pragma treats the Linux kernel as its I/O subsystem. In that setup, Linux thinks it owns the hardware, but Pragma sits above it and provides its own execution model, memory management, scheduling, and IPC — consuming Linux's capabilities through its existing interfaces without forking or reimplementing any of it. All these things get pushed into userspace with tools that make configurability much more simple.

The result is a thin, configurable skeleton that gives you one stop, easy-access control that Linux today offers:

**Process Management & Scheduling**
- Scheduling algorithm selection and composition (CFS, EDF, priority-based, custom)
- Per-workload scheduling policies and CPU affinity
- Core isolation and dedication strategies
- Context switch behavior and preemption granularity
- Process group hierarchies and cgroup-like resource accounting
- Real-time scheduling guarantees and deadline management

**Memory Management**
- Page size selection (4K, 2M, 1G huge pages, mixed)
- NUMA allocation policies and memory placement
- Memory overcommit behavior and OOM strategies
- Swap policies, thresholds, and backend selection
- Transparent huge page behavior per-workload
- DRAM vs CXL-attached memory tiering policies
- Memory bandwidth allocation (Intel MBA / AMD QoS)
- Page reclaim algorithms and cache pressure tuning

**Inter-Process Communication**
- IPC mechanism selection (shared memory, message queues, pipes, custom)
- Zero-copy transfer policies
- IPC namespace isolation and visibility
- Synchronization primitive selection (futex, spinlock, hybrid)
- Lock contention monitoring and adaptive strategies

**Network Stack**
- Protocol stack selection and composition
- TCP congestion control algorithm per-connection or per-workload
- Socket buffer sizing and memory allocation
- RSS (Receive Side Scaling) and RPS/RFS configuration
- XDP/eBPF program attachment points
- Network namespace configuration
- QoS classification and traffic shaping
- Firewall rule compilation strategy (nftables, iptables, or direct)
- Connection tracking table sizing and timeout policies
- Interface bonding, bridging, and VLAN configuration
- MTU and segmentation offload policies
- DNS resolution strategy and caching

**Storage & Persistence**
- Filesystem selection per-mount (ext4, XFS, btrfs, ZFS, tmpfs)
- I/O scheduler selection per-device (none, mq-deadline, BFQ, kyber)
- Readahead and writeback policies
- Journal mode and fsync behavior
- Block layer queue depth and merging
- NVMe multipath and namespace management
- Caching tiers (RAM → NVMe → spinning disk)

**Security & Isolation**
- Namespace configuration (mount, PID, network, user, IPC, cgroup, time)
- Capability sets and privilege boundaries
- Seccomp filter policies
- SELinux/AppArmor policy selection
- IOMMU and DMA protection policies
- Secure boot chain verification
- Kernel lockdown level
- Address space layout randomization (ASLR) behavior
- Stack protector and control flow integrity settings

**Power & Thermal**
- CPU frequency governor selection and parameters
- C-state and P-state policies per-core
- Package-level power limits (RAPL)
- Thermal throttling thresholds and response curves
- Device power management (PCIe ASPM, USB autosuspend)
- Workload-aware power profiles

**Device & Hardware**
- PCIe link speed and width negotiation
- Interrupt affinity and routing (MSI-X distribution)
- DMA engine allocation
- GPU compute vs display resource partitioning
- Peripheral clock gating policies
- Watchdog timer configuration
- ACPI table interpretation overrides

**Observability & Debug**
- Tracing subsystem selection (ftrace, perf, eBPF)
- Logging verbosity and routing per-subsystem
- Performance counter access policies
- Core dump behavior and storage
- Kernel live patching policies
- Audit subsystem configuration


However, Linux can't hot-swap its own scheduler or memory manager while running without kexec or a reboot in most cases. Some things are runtime-tunable (sysctl), some require a reboot (boot parameters), some require recompilation (Kconfig). Pragma's value would be providing a single interface that's runtime-configurable.

---

## But you can already do a lot in Linux, right?

Sure, but if you look at something like the Linux kernel's [`net/`](https://elixir.bootlin.com/linux/v6.19.3/source/net) directory, you'll find ~70 subdirectories at the same level — Bluetooth sitting next to bridge sitting next to IPv4 sitting next to netfilter sitting next to CAN bus. Hardware-specific code, protocol families, filtering frameworks, and utility layers all mixed together with no navigable hierarchy. Not all of them apply to any given system. There's no way to say "show me only what's relevant to *my* hardware, running *these* protocols, using *this* filtering approach" and get a clean, scoped view of the code that actually matters.


What you'd want is something like faceted navigation — pick your hardware, it narrows to applicable protocols; pick a protocol, it narrows to related tooling and configuration. A dependency-aware configuration browser instead of a flat directory listing with 30 years of accumulated everything.

It's not a replacement for Linux — Linux is extraordinary at what it does. While Linux is king of the enterprise server world, it is extremely meager in the personal computing space. The second problem this OS tries to solve is the same thing that made Windows dominate general purpose computing where Linux barely makes a mark: accessibility. By making things accessible to typical enterprise teams and smaller organizations without the spend for specialized hires, they could maximize performance through tweaking settings that were a heck of a lot less easy to work through in the past.




