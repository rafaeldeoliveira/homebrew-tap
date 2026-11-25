class Nautilus < Formula
  desc "GNOME file manager (Files)"
  homepage "https://apps.gnome.org/Nautilus/"
  # GNOME's release plus macOS changes, from
  # https://github.com/rafaeldeoliveira/nautilus (branch "macos")
  url "https://github.com/rafaeldeoliveira/nautilus/archive/refs/tags/v51.2-macos.1.tar.gz"
  version "51.2-macos.1"
  sha256 "a44f2e8801db4ed2b4fed6615861190a7f5f0d24a05bbf268ae65b7676e67be5"
  license "GPL-3.0-or-later"
  head "https://github.com/rafaeldeoliveira/nautilus.git", branch: "macos"

  depends_on "blueprint-compiler" => :build
  depends_on "desktop-file-utils" => :build
  depends_on "librsvg" => :build # rsvg-convert, for the .app icon
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build

  depends_on "adwaita-icon-theme"
  depends_on "cairo"
  depends_on "gdk-pixbuf"
  depends_on "gettext"
  depends_on "glib"
  depends_on "gnome-autoar"
  depends_on "graphene"
  depends_on "gsettings-desktop-schemas"
  depends_on "gtk4"
  depends_on "icu4c@79"
  depends_on "libadwaita"
  depends_on :macos
  depends_on "pango"
  depends_on "tinysparql"

  deny_network_access!

  APP_ID = "org.gnome.Nautilus".freeze
  APP_NAME = "Files".freeze
  ICON_SIZES = [16, 32, 128, 256, 512].freeze
  ICON_SCALES = { 1 => "", 2 => "@2x" }.freeze

  def install
    # Skip meson's post-install scripts (schema and icon caches would land in
    # the keg and clash with other formulae); post_install_steps does it instead.
    ENV["DESTDIR"] = "/"

    # glycin, gnome-desktop (thumbnails), libportal, SELinux and
    # cloudproviders are not available on macOS.
    args = %w[
      -Dglycin=disabled
      -Dthumbnails=disabled
      -Dportal=disabled
      -Dselinux=disabled
      -Dcloudproviders=disabled
      -Dextensions=false
      -Dintrospection=false
      -Ddocs=false
      -Dtests=none
    ]
    system "meson", "setup", "build", *args, *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"

    # A thin .app that launches the keg's binary, so Files gets a Dock icon,
    # a menu bar name, and can open folders from Finder's "Open With".
    contents = prefix/"#{APP_NAME}.app/Contents"
    (contents/"MacOS").mkpath
    (contents/"Resources").mkpath

    launcher = contents/"MacOS/nautilus"
    launcher.write <<~'SH'.sub("@BIN@", "#{opt_bin}/nautilus")
      #!/bin/sh
      # Apps started from Finder get no LANG; derive one from System Settings.
      if [ -z "${LANG:-}" ]; then
        locale_id="$(defaults read -g AppleLocale 2>/dev/null | sed 's/@.*//')"
        if [ -n "$locale_id" ] && locale -a | grep -qx "$locale_id.UTF-8"; then
          export LANG="$locale_id.UTF-8"
        else
          export LANG="en_US.UTF-8"
        fi
      fi
      if [ -z "${LANGUAGE:-}" ]; then
        languages="$(defaults read -g AppleLanguages 2>/dev/null \
          | tr -d ' "(),' | grep -v '^$' | tr '-' '_' | paste -sd: -)"
        [ -n "$languages" ] && export LANGUAGE="$languages"
      fi
      case "${1:-}" in -psn_*) shift ;; esac
      exec "@BIN@" --new-window "$@"
    SH
    launcher.chmod 0755

    (contents/"Info.plist").write <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>CFBundleName</key><string>#{APP_NAME}</string>
        <key>CFBundleDisplayName</key><string>#{APP_NAME}</string>
        <key>CFBundleIdentifier</key><string>#{APP_ID}</string>
        <key>CFBundleExecutable</key><string>nautilus</string>
        <key>CFBundleIconFile</key><string>#{APP_ID}.icns</string>
        <key>CFBundlePackageType</key><string>APPL</string>
        <key>CFBundleShortVersionString</key><string>#{version}</string>
        <key>CFBundleVersion</key><string>#{version}</string>
        <key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
        <key>NSHighResolutionCapable</key><true/>
        <key>CFBundleDocumentTypes</key>
        <array>
          <dict>
            <key>CFBundleTypeName</key><string>Folder</string>
            <key>CFBundleTypeRole</key><string>Viewer</string>
            <key>LSHandlerRank</key><string>Alternate</string>
            <key>LSItemContentTypes</key>
            <array>
              <string>public.folder</string>
            </array>
          </dict>
        </array>
      </dict>
      </plist>
    XML

    iconset = buildpath/"icon.iconset"
    iconset.mkpath
    ICON_SIZES.each do |size|
      ICON_SCALES.each do |scale, suffix|
        px = (size * scale).to_s
        system formula_opt_bin("librsvg")/"rsvg-convert", "-w", px, "-h", px,
               buildpath/"data/icons/hicolor/scalable/apps/#{APP_ID}.svg",
               "-o", iconset/"icon_#{size}x#{size}#{suffix}.png"
      end
    end
    system "iconutil", "-c", "icns", iconset, "-o", contents/"Resources/#{APP_ID}.icns"
  end

  post_install_steps do
    compile_gsettings_schemas
    update_gtk_icon_cache
  end

  def caveats
    <<~EOS
      #{APP_NAME}.app has been installed to:
        #{opt_prefix}/#{APP_NAME}.app

      To add it to your Applications folder (it keeps working across upgrades):
        cp -R "#{opt_prefix}/#{APP_NAME}.app" /Applications/

      Not available on macOS: thumbnails, the Trash and Network views,
      "Set as Background" and "Send to…".
    EOS
  end

  test do
    assert_match "GNOME nautilus", shell_output("#{bin}/nautilus --version")
    assert_path_exists prefix/"#{APP_NAME}.app/Contents/Resources/#{APP_ID}.icns"
    assert_predicate prefix/"#{APP_NAME}.app/Contents/MacOS/nautilus", :executable?
  end
end
