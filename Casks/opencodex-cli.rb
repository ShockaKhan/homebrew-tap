cask "opencodex-cli" do
  arch arm: "arm64", intel: "x64"

  version "2.100.10"
  sha256 arm64_linux:  "815acffa41b7e2c7d8cb64415b13bfde1975ae14ebe079e5b27d5343c6e5fd1d",
         x86_64_linux: "8c1b264b68de2a7a176bdfcd11988386b2e341e4fe68a9ed03aa768bff45448e"

  url "https://github.com/lidge-jun/opencodex/releases/download/v#{version}/ocx-#{version}-bun-linux-#{arch}.tar.gz"
  name "OpenCodex CLI"
  desc "Provider proxy for Codex, Claude Code, and other coding clients"
  homepage "https://github.com/lidge-jun/opencodex"

  livecheck do
    url :url
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    strategy :github_latest
  end

  conflicts_with cask: "opencodex"
  depends_on linux: :any

  # The compiled runtime resolves its dashboard and native addons beside the real executable.
  binary "ocx"
  binary "ocx", target: "opencodex"

  caveats do
    <<~EOS
      Run ocx start to start the proxy, or ocx service to install its background service.
      Open the dashboard at http://localhost:10100.
    EOS
  end
end
