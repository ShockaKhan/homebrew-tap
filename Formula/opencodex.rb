class Opencodex < Formula
  desc "Provider proxy for Codex, Claude Code, and other coding clients"
  homepage "https://github.com/lidge-jun/opencodex"
  version "2.100.8"
  license "MIT"

  if Hardware::CPU.arm?
    url "https://github.com/lidge-jun/opencodex/releases/download/v#{version}/ocx-#{version}-bun-linux-arm64.tar.gz"
    sha256 "7ffd989115d7a6f0ea6057ff3b0ad0bcaf69ce9623924bba16156bcf983839c2"
  else
    url "https://github.com/lidge-jun/opencodex/releases/download/v#{version}/ocx-#{version}-bun-linux-x64.tar.gz"
    sha256 "0be43ef7b27339058db3c37030b9c76fadc3c66f7b011961d1daf1c2f9c7ba1e"
  end

  depends_on :linux

  def install
    # The compiled runtime resolves dashboard and native addons beside its real executable.
    libexec.install "ocx", "gui", "keyring"
    bin.install_symlink libexec/"ocx"
    bin.install_symlink libexec/"ocx" => "opencodex"
  end

  def caveats
    <<~EOS
      Run ocx start to start the proxy, or ocx service to install its background service.
      Open the dashboard at http://localhost:10100.
      Update this installation with brew upgrade --formula shockakhan/tap/opencodex.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/ocx --version")
    assert_match version.to_s, shell_output("#{bin}/opencodex --version")
  end
end
