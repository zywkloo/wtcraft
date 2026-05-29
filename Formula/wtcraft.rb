class Wtcraft < Formula
  desc "Craft bounded multi-agent workflows with git-native worktrees"
  homepage "https://github.com/zywkloo/wtcraft"
  # Update url + sha256 for each release:
  #   curl -sL <url> | shasum -a 256
  url "https://github.com/zywkloo/wtcraft/archive/refs/tags/v0.3.6.tar.gz"
  sha256 "33c7f805ccf815f1ba864908d172ff04a3a06a874ae18ed6c7bc72a9607cc8dc"
  license "Apache-2.0"
  head "https://github.com/zywkloo/wtcraft.git", branch: "main"

  depends_on "bash"
  depends_on "git"

  def install
    # Install templates to pkgshare so the script can find them at runtime.
    pkgshare.install "templates"

    # Install a wrapper that injects WTCRAFT_TEMPLATE_DIR before exec-ing
    # the real script. This is the standard Homebrew pattern for shell scripts
    # that need bundled data files.
    libexec.install "scripts/wtcraft" => "wtcraft-real"

    (bin/"wtcraft").write <<~SH
      #!/usr/bin/env bash
      export WTCRAFT_TEMPLATE_DIR="#{pkgshare}/templates"
      exec "#{libexec}/wtcraft-real" "$@"
    SH
  end

  test do
    system "#{bin}/wtcraft", "--help"
  end
end
