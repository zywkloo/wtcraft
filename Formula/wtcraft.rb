class Wtcraft < Formula
  desc "Craft bounded multi-agent workflows with git-native worktrees"
  homepage "https://github.com/zywkloo/wtcraft"
  # Update url + sha256 for each release:
  #   curl -sL <url> | shasum -a 256
  url "https://github.com/zywkloo/wtcraft/archive/refs/tags/v0.4.2.tar.gz"
  sha256 "f87728f953d187224ca4d9b89351e0647052d6efce651e8c024d60f8aa7511f4"
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
      export WTCRAFT_VERSION="#{version}"
      exec "#{libexec}/wtcraft-real" "$@"
    SH
  end

  test do
    system "#{bin}/wtcraft", "--help"
  end
end
