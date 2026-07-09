const { spawnSync } = require("node:child_process");
const path = require("node:path");

const repoRoot = path.resolve(__dirname, "..");
const isWindows = process.platform === "win32";
const command = isWindows ? "powershell" : "sh";
const scriptPath = path.join(
  repoRoot,
  "scripts",
  isWindows ? "set_windows_paths.ps1" : "set_mac_paths.sh",
);
const args = isWindows
  ? ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", scriptPath]
  : [scriptPath];

const result = spawnSync(command, args, {
  cwd: repoRoot,
  stdio: "inherit",
  shell: false,
});

process.exit(result.status ?? 1);
