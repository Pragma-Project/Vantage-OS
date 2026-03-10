import subprocess, sys, os

REPO_DIR = r"C:\Users\azt12\OneDrive\Documents\Code\Nim OS"
REMOTE   = "https://github.com/taz-public/nimos"

GITIGNORE = """\
build/
limine/
*.log
*.bin
nimos.iso
kernel.elf
nul:
__pycache__/
*.pyc
"""

def run(cmd, **kwargs):
    print(f"  $ {' '.join(cmd)}")
    r = subprocess.run(cmd, cwd=REPO_DIR, capture_output=True, text=True, **kwargs)
    if r.stdout.strip():
        print(r.stdout.strip())
    if r.stderr.strip():
        print(r.stderr.strip())
    return r

os.chdir(REPO_DIR)

# Write .gitignore
with open(os.path.join(REPO_DIR, ".gitignore"), "w", newline="\n") as f:
    f.write(GITIGNORE)
print("Wrote .gitignore")

# Init if needed
if not os.path.isdir(os.path.join(REPO_DIR, ".git")):
    run(["git", "init", "-b", "main"])
else:
    print("  git already initialised")

# Set remote
r = run(["git", "remote", "get-url", "origin"])
if r.returncode != 0:
    run(["git", "remote", "add", "origin", REMOTE])
else:
    run(["git", "remote", "set-url", "origin", REMOTE])

# Stage source files explicitly (no build artifacts)
files = [
    "kernel.nim", "start.S", "linker.ld", "limine.conf", "Makefile",
    "run_qemu.bat", "convert_logo.py", "logo.png", ".gitignore",
    "README.md", "QUICKSTART.md", "BUILD.md", "VMWARE.md",
    "PROJECT_STATUS.md", "panicoverride.nim",
]
for f in files:
    if os.path.exists(os.path.join(REPO_DIR, f)):
        run(["git", "add", f])

run(["git", "commit", "-m", "nimos: working keyboard + filesystem ls"])
run(["git", "push", "-u", "origin", "main"])

print("\nDone.")
