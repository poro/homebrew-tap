class Naive < Formula
  desc "AI-native game engine — create worlds with YAML, Lua, and natural language"
  homepage "https://github.com/poro/nAIVE"
  url "https://github.com/poro/nAIVE/archive/refs/tags/v0.1.7.tar.gz"
  sha256 "9c13a7b5fe8b6fa3304cd279d068a56274de7eb06c3747b9303b82e9b806afcb"
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

    # Install SLANG shared libraries so they're available at runtime
    lib.install Dir[buildpath/"vendor/lib/*.dylib"]

    # Install SLANG standard library modules (needed at runtime for shader compilation)
    (lib/"slang").install Dir[buildpath/"vendor/lib/slang-standard-module-*"]
  end

  test do
    assert_match "nAIVE runtime", shell_output("#{bin}/naive --help 2>&1", 0)
  end
end
