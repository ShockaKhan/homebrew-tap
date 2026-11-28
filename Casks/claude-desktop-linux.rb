cask "claude-desktop-linux" do
  arch arm: "arm64", intel: "amd64"

  version "6.28899.6"
  sha256 arm64_linux:  "239c20d218456cacc656d48382fd59116325ac679aa4e476377af1456ac85715",
         x86_64_linux: "7e381601d86570149643d52e9b89c26575ab12fa788aa41ffdd4cca5b0638cf8"

  url "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_#{version}_#{arch}.deb"
  name "Claude"
  desc "Anthropic's official desktop app for Claude (Linux beta)"
  homepage "https://code.claude.com/docs/en/desktop-linux"

  livecheck do
    url "https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-#{arch}/Packages"
    regex(/^Version:\s*(\d+(?:\.\d+)+)$/i)
  end

  depends_on formula: "dpkg"
  depends_on linux: :any

  binary "usr/lib/claude-desktop/claude-desktop", target: "claude-desktop"
  artifact "usr/share/applications/com.anthropic.Claude.desktop",
           target: "#{Dir.home}/.local/share/applications/com.anthropic.Claude.desktop"
  artifact "usr/share/icons/hicolor/256x256/apps/claude-desktop.png",
           target: "#{Dir.home}/.local/share/icons/claude-desktop.png"

  preflight_steps do
    # Extract only the .deb data archive. Do not run maintainer scripts: they
    # register Anthropic's apt repo and write into privileged system paths.
    remove ["usr", "etc"], recursive: true
    run "{{HOMEBREW_PREFIX}}/opt/dpkg/bin/dpkg-deb",
        args: ["-x", "{{staged_path}}/claude-desktop_{{version}}_{{arch}}.deb", "{{staged_path}}"]
    remove "claude-desktop_{{version}}_{{arch}}.deb"

    inreplace "usr/share/applications/com.anthropic.Claude.desktop", /^Exec=claude-desktop /,
              "Exec={{HOMEBREW_PREFIX}}/bin/claude-desktop ", audit_result: false
    inreplace "usr/share/applications/com.anthropic.Claude.desktop", /^Icon=.*/,
              "Icon=claude-desktop", audit_result: false
  end

  zap trash: [
    "~/.cache/Claude",
    "~/.config/Claude",
    "~/.local/share/Claude",
  ]
end
