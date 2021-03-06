class ThcPptpBruter < Formula
  desc "Brute force program against PPTP VPN endpoints (TCP port 1723)"
  homepage "https://thc.org"
  url "https://freeworld.thc.org/releases/thc-pptp-bruter-0.1.4.tar.gz"
  mirror "https://dl.bintray.com/homebrew/mirror/thc-pptp-bruter-0.1.4.tar.gz"
  sha256 "baa05f398d325b490e3eb4cd0ffaf67a6ae306c968a7d8114267b0c088de6ee2"

  bottle do
    cellar :any
    sha256 "96b0991f521b87d0a839ad676210c5ea940f529c40cb29df81ef7275a26bb09d" => :mojave
    sha256 "ef9ccd5b90616a66263fa9779c31fc3858a32fc5ec0bd69d98df3329072415a7" => :high_sierra
    sha256 "bf0734c5bac73d3948b6b10856c9cff316f28dcac7d5213323f42dcd7f210306" => :sierra
    sha256 "29311d0d9c7592bcaae2acbf529bc6cb836df622361a9343aeb37543a0ff7f48" => :el_capitan
    sha256 "9236475e9ec15fdddefd4b9ad01d619d645ad0227adc50e9ae7c5b01a68ff964" => :yosemite
    sha256 "e34bda13c8753b1064fb59712e799191dd00addfa30b0f9947d2dd97dac47b1a" => :mavericks
  end

  depends_on "openssl"

  def install
    # The function openpty() is defined in pty.h on Linux, but in util.h on macOS.
    # See https://groups.google.com/group/sage-devel/msg/97916255b631e3e5
    inreplace "src/pptp_bruter.c", "pty.h", "util.h"

    system "./configure", "--prefix=#{prefix}"
    system "make"
    system "make", "install"
  end

  test do
    system "#{bin}/thc-pptp-bruter"
  end
end
