{
  mkGodot =
    {
      lib,
      stdenv,
      patchelf,
      copyDesktopItems,
      godot,
      export-templates,
    }:
    {
      pname,
      version,
      src,
      preset,
      meta ? {
        mainProgram = "${pname}";
      },
      desktopItems ? [ ],
      exportMode ? "release",
    }:
    stdenv.mkDerivation {
      inherit
        pname
        version
        src
        desktopItems
        meta
        ;

      buildInputs = [
        copyDesktopItems
        godot
        patchelf
      ];
      preBuild = ''
        export TEMPDIR=$(mktemp -d)
        export HOME=$TEMPDIR
        if [ ! -f export_presets.cfg ]; then
            echo "Error: export_presets.cfg not found in source directory"
            echo "Please setup export_presets.cfg first with the '${preset}' preset"
            exit 1
        fi
        export PLATFORM=$(awk -F'=' '
        $1 == "name" && $2 == "\"${preset}\"" {
            getline;
            if ($1 == "platform") {
                gsub(/"/, "", $2);
                print $2;
                exit;
            }
        }' export_presets.cfg)
      '';
      buildPhase = ''
        runHook preBuild
        templates="${export-templates}/share/godot/export_templates"
        mkdir -p $HOME/.local/share/godot/
        ln -s $templates $HOME/.local/share/godot/export_templates
        sed -i '/custom_template/ s/"[^"]*"/""/g' export_presets.cfg
        mkdir -p $out/share/${pname}
        if [ "$PLATFORM" == "Web" ]; then
            ${lib.getExe godot} --headless --import --export-${exportMode} "${preset}" $out/share/${pname}/index.html
        elif [ "$PLATFORM" == "Windows Desktop" ]; then
            ${lib.getExe godot} --headless --import --export-${exportMode} "${preset}" $out/share/${pname}/${pname}.exe
        elif [ "$PLATFORM" == "Android" ]; then
            ${lib.getExe godot} --headless --import --export-${exportMode} "${preset}" $out/share/${pname}/${pname}.apk
        elif [ "$PLATFORM" == "Linux" ]; then
            ${lib.getExe godot} --headless --import --export-${exportMode} "${preset}" $out/share/${pname}/${pname}
        else
            echo "Error: preset '${preset}' has a platform that is not handled in this script"
            exit 1
        fi
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p $out/bin
        if [ "$PLATFORM" == "Linux" ]; then
            patchelf --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) $out/share/${pname}/${pname} || true
            ln -s $out/share/${pname}/${pname} $out/bin/${pname}
        elif [ "$PLATFORM" == "Windows Desktop" ]; then
            ln -s $out/share/${pname}/${pname}.exe $out/bin/${pname}.exe
        else
            ln -s $out/share/${pname}/* $out/bin/
        fi
        runHook postInstall
      '';

      postBuild = ''
        rm -rf $TEMPDIR
      '';
    };

  mkGodotNixosPatch =
    {
      stdenv,
      copyDesktopItems,
      installShellFiles,
      autoPatchelfHook,
      vulkan-loader,
      libGL,
      alsa-lib,
      wayland,
      fontconfig,
      libxkbcommon,
      libx11,
      libxcursor,
      libxinerama,
      libxext,
      libxrandr,
      libxrender,
      libxi,
      libxfixes,
    }:
    {
      pname,
      version,
      src,
      desktopItems ? [ ],
    }:
    stdenv.mkDerivation {
      inherit
        pname
        version
        src
        desktopItems
        ;
      nativeBuildInputs = [
        autoPatchelfHook
        installShellFiles
        copyDesktopItems
      ];
      runtimeDependencies = [
        vulkan-loader
        libGL
        wayland
        fontconfig
        libx11
        libxcursor
        libxinerama
        libxext
        libxrandr
        libxrender
        libxi
        libxfixes
        libxkbcommon
        alsa-lib
      ];
      installPhase = ''
        runHook preInstall
        mkdir $out
        mv bin/* bin/${pname} || true # Rename fails if pname is the same
        cp -r * $out
        runHook postInstall
      '';
    };
}
