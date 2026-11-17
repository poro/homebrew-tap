class Naive < Formula
  desc "AI-native game engine — create worlds with YAML, Lua, and natural language"
  homepage "https://github.com/poro/nAIVE"
  # Built by the release workflow with the Git LFS meshes that include_bytes!
  # embeds; GitHub's automatic archives can hold LFS pointers instead.
  url "https://github.com/poro/nAIVE/releases/download/v0.1.23/nAIVE-0.1.23-source.tar.gz"
  sha256 "0284f178379646fe9a0bd29bcd26a2f8d8df5233a51fafb5a36ffd4363a26b85"
  license "MIT"

  depends_on "rust" => :build

  # NVIDIA SLANG shader compiler SDK
  resource "slang" do
    on_arm do
      url "https://github.com/shader-slang/slang/releases/download/v2026.2.2/slang-2026.2.2-macos-aarch64.tar.gz"
      sha256 "44dfa55395fd0f1616956f3f2f0a3ec7fff930e33585ec2277abb6427b2a63a9"
    end
    on_intel do
      url "https://github.com/shader-slang/slang/releases/download/v2026.2.2/slang-2026.2.2-macos-x86_64.tar.gz"
      sha256 "af420111d93ebe7f6a31f48c8f7e35d63316b79d8f9e3c344dd77ddef82051e9"
    end
  end

  def install
    # Stage SLANG SDK into vendor/ for the build
    resource("slang").stage do
      (buildpath/"vendor").install Dir["*"]
    end

    # Tell shader-slang-sys where to find the SDK
    ENV["SLANG_DIR"] = buildpath/"vendor"

    # Set rpath so the installed binary can find SLANG dylibs at runtime
    ENV["RUSTFLAGS"] = "-C link-arg=-Wl,-rpath,#{lib}"

    # Build and install the naive-runtime crate (produces naive + naive-runtime + naive_mcp binaries)
    system "cargo", "install", *std_cargo_args(path: "crates/naive-runtime")

    # naive-player: naive without Slang, which `naive build` ships in game
    # bundles. Its own cargo install builds it without the slang feature.
    system "cargo", "install", *std_cargo_args(path: "crates/naive-player")

    # Install SLANG shared libraries so they're available at runtime
    lib.install Dir[buildpath/"vendor/lib/*.dylib"]

    # Install SLANG standard library modules (needed at runtime for shader compilation)
    (lib/"slang").install Dir[buildpath/"vendor/lib/slang-standard-module-*"]
  end

  test do
    assert_match "AI-Native Game Engine", shell_output("#{bin}/naive --help 2>&1")
    assert_match "AI-Native Game Engine", shell_output("#{bin}/naive-player --help 2>&1")
    # Game bundles must run without the Slang libraries.
    refute_match(/slang/i, shell_output("otool -L #{bin}/naive-player"))
  end
end
