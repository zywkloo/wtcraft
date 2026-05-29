class Wtcraft < Formula
  desc "Craft bounded multi-agent workflows with git-native worktrees"
  homepage "https://github.com/zywkloo/wtcraft"
  # Update url + sha256 for each release:
  #   curl -sL <url> | shasum -a 256
  url "https://github.com/zywkloo/wtcraft/archive/refs/tags/v0.3.5.tar.gz"
  sha256 "b02f78a26ac8b1b665f37e2c47513f46361b0a27ee8c5d5020b69df9ee52d264"
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
