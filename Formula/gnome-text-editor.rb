class GnomeTextEditor < Formula
  desc "Simple, modern text editor from GNOME"
  homepage "https://apps.gnome.org/TextEditor/"
  url "https://download.gnome.org/sources/gnome-text-editor/51/gnome-text-editor-51.0.tar.xz"
  sha256 "2b76e6da1506346c54b36ba1a3aeedcd28f4cb7d6a8793d217f209456c92dd4c"
  license "GPL-3.0-or-later"
  head "https://gitlab.gnome.org/GNOME/gnome-text-editor.git", branch: "main"

  depends_on "desktop-file-utils" => :build
  depends_on "itstool" => :build
  depends_on "librsvg" => :build # rsvg-convert, for the .app icon
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build

  depends_on "adwaita-icon-theme"
  depends_on "editorconfig"
  depends_on "gettext"
  depends_on "glib"
  depends_on "gtk4"
  depends_on "gtksourceview5"
  depends_on "libadwaita"
  depends_on "libspelling"
  depends_on :macos
  depends_on "pango"

  deny_network_access!

  APP_ID = "org.gnome.TextEditor".freeze
  APP_NAME = "Text Editor".freeze
  ICON_SIZES = [16, 32, 128, 256, 512].freeze
  ICON_SCALES = { 1 => "", 2 => "@2x" }.freeze

  def install
    # Skip meson's post-install scripts (schema and icon caches would land in
    # the keg and clash with other formulae); post_install_steps does it instead.
    ENV["DESTDIR"] = "/"

    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"

    # A thin .app that launches the keg's binary, so the editor gets a Dock
    # icon, a menu bar name, and can be used from Finder's "Open With".
    contents = prefix/"#{APP_NAME}.app/Contents"
    (contents/"MacOS").mkpath
    (contents/"Resources").mkpath

    launcher = contents/"MacOS/gnome-text-editor"
    launcher.write <<~'SH'.sub("@BIN@", "#{opt_bin}/gnome-text-editor")
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
      exec "@BIN@" "$@"
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
        <key>CFBundleExecutable</key><string>gnome-text-editor</string>
        <key>CFBundleIconFile</key><string>#{APP_ID}.icns</string>
        <key>CFBundlePackageType</key><string>APPL</string>
        <key>CFBundleShortVersionString</key><string>#{version}</string>
        <key>CFBundleVersion</key><string>#{version}</string>
        <key>LSApplicationCategoryType</key><string>public.app-category.developer-tools</string>
        <key>NSHighResolutionCapable</key><true/>
        <key>CFBundleDocumentTypes</key>
        <array>
          <dict>
            <key>CFBundleTypeName</key><string>Text Document</string>
            <key>CFBundleTypeRole</key><string>Editor</string>
            <key>LSHandlerRank</key><string>Alternate</string>
            <key>LSItemContentTypes</key>
            <array>
              <string>public.text</string>
              <string>public.plain-text</string>
              <string>public.source-code</string>
              <string>public.script</string>
              <string>public.json</string>
              <string>public.xml</string>
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
               buildpath/"data/icons/#{APP_ID}.svg",
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
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/gnome-text-editor --version")
    assert_path_exists prefix/"#{APP_NAME}.app/Contents/Resources/#{APP_ID}.icns"
    assert_predicate prefix/"#{APP_NAME}.app/Contents/MacOS/gnome-text-editor", :executable?
  end
end
