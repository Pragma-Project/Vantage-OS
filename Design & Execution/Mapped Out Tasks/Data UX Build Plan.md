# Pragma OS — Full Build Plan

Each section below is a self-contained workstream. Each one lists the packages involved, what exists vs what needs building, concrete steps, and a Claude-promptable description of the work.

---

## 1. Stripped Linux Kernel Build

**Goal:** Minimal Linux kernel that keeps hardware drivers and removes all policy/UI/unnecessary subsystems.

**Packages:** Linux kernel source (kernel.org), Buildroot or manual Kconfig

**What exists:** Everything. This is configuration work, not code.

**Steps:**
- Start from `make defconfig` for your target architecture (x86_64)
- Disable: all sound (ALSA/PulseAudio), all input beyond PS/2 and USB HID, all filesystems except ext4/tmpfs/proc/sysfs/devtmpfs, Bluetooth, wireless (unless needed), printing/CUPS support, all framebuffer console drivers beyond basic VGA/EFI, SELinux and AppArmor (Pragma replaces), audit subsystem, cgroups v1 (keep v2), legacy SCSI drivers, all wireless regulatory database, amateur radio, ISDN, ATM networking, InfiniBand (unless needed), NFS client/server (unless needed)
- Keep: all PCIe/NVMe/SATA/USB storage drivers, all ethernet NIC drivers for target hardware, IOMMU/VT-d, KVM (if virtualization needed), eBPF/BPF, sched_ext, netfilter (minimal), DPDK-compatible VFIO/UIO drivers, hugepage support, NUMA support, perf subsystem
- Compile and test boot on target hardware or QEMU
- Measure boot time and memory footprint vs stock Ubuntu kernel
- Test: all target NICs get link, all storage devices mount, GPU is visible via lspci and nvidia-smi

**Claude prompt:** "I have a Linux 6.x kernel source tree. Help me create a minimal .config that keeps all hardware drivers (PCIe, NVMe, SATA, USB, ethernet NICs, GPU passthrough via VFIO) but removes all policy components (scheduler can be replaced via sched_ext, remove SELinux/AppArmor, remove sound, remove Bluetooth, remove all unnecessary filesystems). Target is x86_64 server with Intel Xeon or AMD EPYC. Give me the specific Kconfig symbols to disable and why."

---

## 2. Pragma Config Service

**Goal:** Single config file that generates all the scattered Linux config files (systemd units, sysctl, modprobe, etc.) and a web GUI to edit it.

**Packages:** Python or Go for the daemon, React or Svelte for GUI, TOML/YAML parser

**What exists:** The individual Linux config systems all exist. The unified layer does not.

**Steps:**
- Define the Pragma config schema in TOML or YAML covering: services (name, command, user, restart policy, resource limits), kernel params (maps to sysctl), module params (maps to modprobe.d), boot params (maps to kernel cmdline), network config (maps to networkd/netplan)
- Build `pragma-configd` daemon that: reads `/etc/pragma.conf`, generates appropriate systemd unit files in a managed directory, writes sysctl.d entries, writes modprobe.d entries, watches for config changes and reloads affected subsystems
- Build web GUI: single-page app that reads config via REST API, presents forms with dropdowns/sliders/toggles per section, writes back via API, shows live validation
- Build CLI: `pragma config show`, `pragma config set services.ocr.max_memory 8G`, `pragma config reload`
- Test: change a value in GUI, verify the underlying Linux config file updates, verify the service restarts with new limits

**Claude prompt:** "Build a Python daemon called pragma-configd that reads a single TOML config file at /etc/pragma.conf and generates: systemd service unit files, sysctl.d config files, and modprobe.d config files. The TOML schema should have sections for [services], [kernel], [modules], and [network]. Include a FastAPI REST endpoint that the web GUI will call. When the config file changes, the daemon should regenerate affected files and reload the relevant subsystem (systemctl daemon-reload, sysctl --system, etc.)."

---

## 3. Job/Dataset/Artifact Tracker

**Goal:** OS-level service that tracks every pipeline run, its parameters, status, outputs, and lets you query/diff them.

**Packages:** SQLite (metadata store), Python/Go (daemon), FastAPI or similar (API)

**What exists:** Nothing as a unified package. MLflow is closest but it's ML-specific and doesn't track arbitrary artifacts or do dataset versioning.

**Steps:**
- Design schema: jobs table (id, name, pipeline, status, params JSON, start_time, end_time), artifacts table (id, job_id, filepath, size, hash, type, tags JSON), datasets table (id, name, version, schema JSON, job_id, row_count)
- Build `pragma-trackerd` daemon with SQLite backend
- On job start: pipeline daemon calls tracker API with job name, pipeline, params → gets job ID back
- On artifact creation: pipeline daemon registers each output file with job ID, type, tags
- On job end: pipeline daemon updates status, duration
- Build CLI: `pragma job list`, `pragma job show <id>`, `pragma job diff <id1> <id2>`, `pragma dataset list`, `pragma dataset show <name> --version 3`
- Build API endpoints for GUI consumption
- Test: run a pipeline, verify all artifacts tracked, run again with different params, diff the two runs

**Claude prompt:** "Build a Python service called pragma-tracker with a SQLite backend and FastAPI REST API. Schema: jobs (id, name, pipeline_name, status, params_json, start_time, end_time), artifacts (id, job_id, filepath, size_bytes, sha256, file_type, tags_json, created_at), datasets (id, name, version, schema_json, source_job_id, row_count, created_at). API endpoints: POST /jobs (create), PATCH /jobs/{id} (update status), POST /artifacts (register), GET /jobs (list with filters), GET /jobs/{id} (detail with artifacts), GET /jobs/diff/{id1}/{id2} (compare two runs). Include CLI wrapper using Click that calls the API."

---

## 4. Search and Metadata Index

**Goal:** Full-text search across PDFs, OCR text, and structured metadata with tag filtering.

**Packages:** SQLite FTS5 (full-text search built into SQLite), pdftotext or PyMuPDF (PDF text extraction), Python

**What exists:** The individual tools exist. The unified search layer does not.

**Steps:**
- Extend the tracker database with an FTS5 virtual table for full-text content
- When an artifact is registered and it's a PDF or text file: extract text, insert into FTS5 index with job_id and artifact_id as metadata
- When tags are added to an artifact or dataset: index those too
- Build search endpoint: `GET /search?q=credit+spread&tag=topic:fixed_income&year=2021` that queries FTS5 with tag filters
- Build CLI: `pragma search "credit spread" --tag topic:fixed_income --year 2021`
- Build GUI search panel: search bar + tag filter checkboxes + results showing matched documents with highlighted snippets
- Test: index 500 PDFs, search for a known phrase, verify results include correct documents with snippets

**Claude prompt:** "Extend the pragma-tracker SQLite database with an FTS5 virtual table for full-text search. When a PDF or text artifact is registered, extract the text content (using PyMuPDF for PDFs) and insert it into the FTS5 table linked to the artifact ID. Add a search API endpoint GET /search that accepts a query string and optional tag filters, runs an FTS5 MATCH query joined with the artifacts and jobs tables, and returns results with highlighted snippets. Include pagination."

---

## 5. Pipeline Daemon

**Goal:** Lightweight service that reads pipeline definitions (YAML), executes steps in sequence or parallel, handles retries, logging, and resource limits, and reports to the job tracker.

**Packages:** Python, PyYAML, subprocess, pragma-tracker (from #3)

**What exists:** Airflow/Prefect/Dagster exist but are heavy. Nothing lightweight and standalone.

**Steps:**
- Define pipeline YAML schema: name, steps (ordered list), each step has a type (pull, ocr, summarize, extract_tables, export), a backend reference, and optional params
- Build `pragma-pipelined` daemon that: reads pipeline YAML files from `/etc/pragma/pipelines/`, exposes API to trigger a run with input params, on trigger: creates a job via tracker API, executes each step as a subprocess, captures stdout/stderr to log files registered as artifacts, respects retry count and parallelism settings, on completion updates job status via tracker
- Resource limits: use cgroups v2 to enforce memory/CPU limits per step subprocess
- Parallelism: for steps marked parallel, use multiprocessing pool capped at configured concurrency
- Build CLI: `pragma pipeline list`, `pragma pipeline run scholarsweep --query "bond yields" --years 2020-2024`
- Build API for GUI: POST /pipeline/run, GET /pipeline/{job_id}/status (with live step progress)
- Test: define a 3-step pipeline, run it, verify tracker has job with artifacts, kill a step mid-run and verify retry

**Claude prompt:** "Build a Python service called pragma-pipelined that reads pipeline definitions from YAML files. Each pipeline has a name, a list of steps (each with type, backend, and params), retry count, parallelism limit, and memory limit. When triggered via POST /pipeline/run with pipeline name and input params, it: creates a job via the pragma-tracker API, executes each step as a subprocess in sequence (or parallel where configured), enforces memory limits via cgroups v2, captures logs as artifacts, handles retries on failure, and updates job status on completion. Use asyncio for managing concurrent step execution."

---

## 6. Collections GUI

**Goal:** Web-based interface where users manage named collections of documents, run pipelines on them, and browse results.

**Packages:** React or Svelte (frontend), pragma-tracker API (backend), pragma-pipelined API (backend)

**What exists:** Nothing like this as a standalone tool.

**Steps:**
- Design UI layout: left panel = collections list, right panel = collection contents (documents, tables, notes), top bar = actions (run pipeline, search, filter)
- Collections are stored in the tracker database as a new table: collections (id, name, description, created_at) with a join table collection_artifacts linking artifacts to collections
- Build frontend: collection CRUD (create, rename, delete), drag artifacts into collections or auto-populate from a job, run pipeline on collection (calls pipelined API), show job history per collection, show dataset versions
- Build API endpoints: CRUD for collections, link/unlink artifacts, get collection contents with metadata
- Right-click context menu on items: open PDF, view OCR text, view extracted tables, add note, compare versions
- Test: create collection, run pipeline, verify results appear in collection, add manual note, search within collection

**Claude prompt:** "Build a React single-page application for managing document collections. Left sidebar shows a list of collections (fetched from GET /collections API). Clicking a collection shows its contents in the main panel: PDFs, extracted tables, OCR text, notes. Top bar has a 'Run Pipeline' dropdown that lists available pipelines (from GET /pipelines API) and triggers a run via POST /pipeline/run. Show live job progress. Each item has a context menu with: Open, View OCR Text, View Tables, Add Note. Include a search bar that calls GET /search filtered to the current collection. Use Tailwind CSS for styling."

---

## 7. Plugin System

**Goal:** Standard interface contracts for OCR, LLM, and table extraction backends, swappable via one config change.

**Packages:** Python (interface definitions), existing backends (Tesseract, PaddleOCR, Ollama/vLLM, Camelot/Tabula)

**What exists:** Each backend exists independently. The abstraction layer does not.

**Steps:**
- Define plugin protocol: each plugin is an executable that reads JSON from stdin and writes JSON to stdout. OCR plugin: input `{"file": "/path/to/pdf", "pages": [1,2,3]}`, output `{"text": "...", "confidence": 0.95}`. LLM plugin: input `{"prompt": "...", "context": "..."}`, output `{"response": "...", "tokens": 450}`. Table plugin: input `{"file": "/path/to/pdf", "page": 3}`, output `{"tables": [{"headers": [...], "rows": [...]}]}`
- Build plugin registry: YAML file at `/etc/pragma/plugins.yaml` listing available plugins with name, type, executable path, protocol version
- Build plugin runner in the pipeline daemon: when a step says `type: ocr`, look up the active OCR plugin, spawn it, pipe JSON in, read JSON out
- Build CLI: `pragma plugin list`, `pragma plugin set ocr paddleocr`, `pragma plugin test ocr --input sample.pdf`
- Write wrapper scripts for existing tools: `tesseract-plugin.py` (wraps tesseract CLI into JSON protocol), `paddleocr-plugin.py` (wraps PaddleOCR Python API), `ollama-plugin.py` (wraps Ollama API), `camelot-plugin.py` (wraps Camelot)
- Test: install two OCR backends, switch between them via config, verify pipeline produces output from both

**Claude prompt:** "Build a plugin system for Pragma. Plugins are executables that communicate via JSON over stdin/stdout. Define three plugin types: ocr (input: file path, output: text + confidence), llm (input: prompt + context, output: response + token count), table_extract (input: file path + page, output: array of tables with headers and rows). Build a plugin registry that reads /etc/pragma/plugins.yaml listing available plugins. Build a plugin runner class that spawns the plugin subprocess, sends input JSON, reads output JSON, with timeout handling. Then write four wrapper scripts: tesseract-plugin.py, paddleocr-plugin.py, ollama-plugin.py, and camelot-plugin.py that wrap each existing tool into the JSON protocol."

---

## 8. Observability Dashboard

**Goal:** Single dashboard showing system metrics, GPU status, job progress, and per-step timing, aggregated from existing Linux tools.

**Packages:** Python (collector daemon), psutil (CPU/RAM/disk), pynvml (GPU metrics from NVIDIA), FastAPI (API), React (dashboard)

**What exists:** All data sources exist. The aggregation and unified dashboard do not.

**Steps:**
- Build `pragma-metricsd` daemon that polls every 1-2 seconds: CPU per-core usage (from /proc/stat), RAM usage and breakdown (from /proc/meminfo), disk IO rates (from /proc/diskstats), network throughput (from /proc/net/dev), GPU utilization and VRAM (from pynvml/NVML library), active jobs and their step progress (from pragma-tracker API)
- Store recent metrics in a ring buffer (last 1 hour) in memory
- Expose via API: GET /metrics/current (latest snapshot), GET /metrics/history?duration=1h (time series), GET /metrics/jobs (active job details with per-step timing)
- Build dashboard frontend: top row = gauges (CPU, RAM, GPU, disk, net), middle = active jobs with progress bars and per-step timing, bottom = alerts (slow steps, high memory, GPU thermal throttling)
- Optional: export metrics in Prometheus format for users who want Grafana
- Test: run a GPU-heavy pipeline, verify dashboard shows GPU utilization spike, verify per-step timing is accurate

**Claude prompt:** "Build a Python daemon called pragma-metricsd that collects system metrics every 2 seconds: CPU per-core from /proc/stat, memory from /proc/meminfo, disk IO from /proc/diskstats, network from /proc/net/dev, and GPU metrics using pynvml. Store the last hour of metrics in an in-memory ring buffer. Expose via FastAPI: GET /metrics/current returns latest snapshot, GET /metrics/history returns time series. Also poll the pragma-tracker API for active job status and include that in the response. Build a React dashboard that shows live gauges for CPU/RAM/GPU/disk/net updating every 2 seconds via polling, a table of active jobs with progress bars, and an alerts section that flags anomalies like steps taking >3x expected duration."

---

## 9. DPDK + F-Stack Integration (High-Performance Networking)

**Goal:** Optional high-performance networking path using DPDK + F-Stack (FreeBSD TCP stack) for latency-sensitive workloads, alongside Linux's native stack for everything else.

**Packages:** DPDK (dpdk.org), F-Stack (github.com/F-Stack/f-stack), Linux VFIO driver

**What exists:** Both DPDK and F-Stack are production-ready. Integration into Pragma's config system does not exist.

**Steps:**
- This is an advanced optional component — build last
- Install DPDK: compile from source, bind target NIC to VFIO-PCI driver, configure hugepages (1024 x 2MB pages = 2GB)
- Install F-Stack: compile against DPDK, configure f-stack.conf with NIC port, IP address, core affinity
- Test basic F-Stack: run F-Stack's built-in Nginx example, benchmark with wrk, compare latency against native Linux Nginx
- Integrate into Pragma config: add [network.highperf] section to pragma.conf specifying which NICs use DPDK/F-Stack vs Linux native stack
- Build pragma-netd wrapper that: on boot, checks config, binds specified NICs to VFIO, starts F-Stack, routes specified traffic through F-Stack
- Dual-stack operation: NIC0 (management, SSH, general) = Linux native stack, NIC1 (data plane, serving) = F-Stack
- Test: verify SSH still works on Linux stack while high-performance traffic runs through F-Stack on separate NIC

**Claude prompt:** "Help me set up DPDK + F-Stack on Ubuntu 22.04. I have two NICs: eth0 for management (stays on Linux stack) and eth1 for high-performance serving (will use F-Stack). Walk me through: installing DPDK from source, binding eth1 to vfio-pci, setting up hugepages, compiling F-Stack against DPDK, configuring f-stack.conf, and running F-Stack's example Nginx. Then help me benchmark it against standard Linux Nginx using wrk. Show me the specific commands for each step."

---

## 10. SPDK Integration (High-Performance Storage)

**Goal:** Optional high-performance storage path using SPDK for direct NVMe access, bypassing the kernel block layer.

**Packages:** SPDK (spdk.io), DPDK (dependency)

**What exists:** SPDK is production-ready. Integration does not exist.

**Steps:**
- This is advanced and optional — only needed if storage IO is the bottleneck
- Install SPDK: compile from source (depends on DPDK), bind target NVMe device to VFIO or UIO
- Test basic SPDK: run SPDK's perf benchmark tool, compare IOPS against kernel fio benchmark on same device
- Determine use case: SPDK makes sense for databases that manage their own storage (like ScyllaDB) but not for general filesystem access, since SPDK bypasses the filesystem entirely
- If needed: use SPDK's BlobFS for a simple non-POSIX filesystem, or use SPDK as the storage backend for a specific application while keeping the kernel filesystem for everything else
- Integrate into Pragma config: add [storage.highperf] section specifying which NVMe devices use SPDK vs kernel
- Test: verify system disk still works normally while target NVMe is managed by SPDK

**Claude prompt:** "Help me set up SPDK on Ubuntu 22.04. I have two NVMe drives: nvme0 for the OS (stays on kernel ext4) and nvme1 for high-performance data (will use SPDK). Walk me through: installing SPDK from source, binding nvme1 to the SPDK driver, running the SPDK perf benchmark, and comparing IOPS against kernel fio on the same device. Show specific commands."

---

## 11. Pragma Policy Layer (Kernel Space)

**Goal:** Kernel modules and eBPF programs that override Linux's scheduling, memory, and security policy decisions.

**Packages:** Linux kernel headers, BPF CO-RE (libbpf), sched_ext, C

**What exists:** sched_ext (merged in kernel 6.12), eBPF infrastructure, kernel module framework. Custom policy implementations do not exist.

**Steps:**
- Start with sched_ext: write a custom scheduler as a BPF program that reads scheduling policy from pragma.conf (via shared memory or BPF maps) — e.g., "pin pipeline OCR workers to cores 0-3, LLM inference to cores 4-7"
- Memory policy: write eBPF programs that attach to memory allocation hooks, enforce per-job NUMA placement based on pragma.conf
- Network policy: write XDP programs for traffic classification and QoS based on pragma.conf rules
- Security policy: write eBPF LSM (Linux Security Module) programs that enforce Pragma's security rules instead of SELinux/AppArmor
- Each policy module reads its config from BPF maps that the pragma-configd daemon populates when config changes
- Hot-reloadable: when config changes, configd updates BPF maps, policies take effect immediately without reboot
- Test: load custom scheduler, verify workloads get pinned to configured cores, change config, verify repin happens live

**Claude prompt:** "Write a sched_ext BPF scheduler for Linux 6.12+ that reads CPU affinity rules from a BPF map. The map is keyed by cgroup ID and the value specifies which CPU cores that cgroup's tasks should run on. Include a userspace loader program that reads from /etc/pragma.conf, parses the [scheduling] section, and populates the BPF map. When the config file changes, the loader should update the map and the scheduler should pick up the new affinities on the next scheduling decision. Use libbpf and BPF CO-RE."

---

## 12. Metal — Firmware Optimizer

**Goal:** Bayesian optimization tool that systematically explores FSP/AGESA parameter space to find optimal firmware configurations for a given workload.

**Packages:** botorch, gpytorch, torch, flashrom, stress-ng, STREAM benchmark, Intel MLC

**What exists:** botorch exists. The firmware manipulation and benchmark harness do not.

**Steps:**
- Build parameter space definition tool: reads from the FSP param catalog JSON, engineer annotates which params are safe to tune and defines bounds
- Build firmware image manipulator: given a base coreboot image and a set of UPD value overrides, produce a modified firmware image (using coreboot's build system or direct binary patching)
- Build benchmark harness: script that runs a configurable suite of benchmarks (STREAM for memory bandwidth, stress-ng for CPU, fio for storage, custom workload scripts), collects results into a standard JSON format
- Build flash-and-test loop: flash image via flashrom, reboot (via IPMI/BMC), wait for OS to come up, run benchmark harness, collect results, report back to optimizer
- Build optimizer: botorch MixedSingleTaskGP for mixed categorical/continuous params, acquisition function selects next configuration, loop until convergence or budget exhausted
- Build results dashboard: show parameter configurations tested, benchmark scores, convergence plot, best configuration found
- Test: on a test server, optimize 3-5 safe parameters (SNC mode, prefetcher enables, turbo mode) across 20 iterations, verify the optimizer finds a measurably better configuration than defaults

**Claude prompt:** "Build a Python application called pragma-metal that uses botorch to optimize firmware parameters. It needs: (1) A parameter space loader that reads a JSON file defining parameters with name, type (categorical or continuous), allowed values or bounds, and default. (2) A MixedSingleTaskGP model setup using botorch that handles both categorical params (like SNC mode: off/snc2/snc4) and continuous params (like power limits). (3) An acquisition function (Expected Improvement) with optimize_acqf_mixed for the mixed space. (4) A benchmark harness interface that takes a configuration dict, returns a score dict. (5) A main optimization loop that: runs N initial random configurations, fits the model, asks for next candidate, runs benchmark, updates model, repeats for B iterations. Include logging of every configuration tested and its score to a SQLite database."

---

## Build Order

1. **Stripped kernel** (#1) — foundation, no dependencies
2. **Config service** (#2) — everything else reads from this
3. **Job tracker** (#3) — pipelines and GUI depend on this
4. **Search index** (#4) — extends tracker, small incremental work
5. **Plugin system** (#7) — pipelines need this to call backends
6. **Pipeline daemon** (#5) — depends on tracker and plugins
7. **Collections GUI** (#6) — depends on tracker and pipelines
8. **Observability** (#8) — can be built in parallel with GUI
9. **Policy layer** (#11) — kernel-space work, independent track
10. **Metal optimizer** (#12) — independent track, already started
11. **DPDK/F-Stack** (#9) — advanced, build last
12. **SPDK** (#10) — advanced, build last
