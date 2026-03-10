import subprocess, os

REPO_DIR = r"C:\Users\azt12\OneDrive\Documents\Code\Nim OS"
REMOTE   = "https://github.com/taz-public/nimos"
TOKEN    = "REDACTED"

FILES = [
    "kernel.nim", "VFS.nim", "start.S", "linker.ld", "limine.conf", "Makefile", "push.bat",
    "run_qemu.bat", "convert_logo.py", "logo.png", ".gitignore",
    "README.md", "QUICKSTART.md", "BUILD.md", "VMWARE.md",
    "PROJECT_STATUS.md", "panicoverride.nim",
]

def run(cmd):
    print(f"  $ {' '.join(cmd)}")
    r = subprocess.run(cmd, cwd=REPO_DIR, capture_output=True, text=True)
    if r.stdout.strip(): print(r.stdout.strip())
    if r.stderr.strip(): print(r.stderr.strip())
    return r

os.chdir(REPO_DIR)

for f in FILES:
    if os.path.exists(os.path.join(REPO_DIR, f)):
        run(["git", "add", f])

run(["git", "commit", "-m", "update"])
run(["git", "remote", "set-url", "origin", f"https://taz-public:{TOKEN}@github.com/taz-public/nimos"])
run(["git", "push", "-u", "origin", "main", "--force"])
run(["git", "remote", "set-url", "origin", REMOTE])

print("\nDone.")
