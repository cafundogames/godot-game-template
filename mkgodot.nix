{
  mkGodotGame =
    {
      stdenvNoCC,
      patchelf,
      godot,
      export-templates ? godot.export-templates-bin,
      pname,
      version,
      src,
      preset,
      meta ? {
        mainProgram = "${pname}";
      },
      ...
    }:
    stdenvNoCC.mkDerivation {
      inherit
        version
        src
        meta
        ;
      pname = "${pname}-${preset}";

      buildInputs = [
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
            ${godot}/bin/godot --headless --import --export-release "${preset}" $out/share/${pname}/index.html
        elif [ "$PLATFORM" == "Windows Desktop" ]; then
            ${godot}/bin/godot --headless --import --export-release "${preset}" $out/share/${pname}/${pname}.exe
        elif [ "$PLATFORM" == "Linux" ]; then
            ${godot}/bin/godot --headless --import --export-release "${preset}" $out/share/${pname}/${pname}
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
            ln -s $out/share/${pname}/${pname} $out/bin/${pname}
        else
            echo "Platforms other than Linux do not need this step. All files can be found at $out/share/${pname}/"
        fi
        runHook postInstall
      '';

      postBuild = ''
        rm -rf $TEMPDIR
      '';
    };

  patchGodotGame =
    {
      stdenvNoCC,
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
      src,
      pname,
      ...
    }:
    stdenvNoCC.mkDerivation {
      inherit src;
      inherit (src) version meta;

      pname = "${pname}-nixos";
      nativeBuildInputs = [
        autoPatchelfHook
        installShellFiles
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
        cp -r * $out
        runHook postInstall
      '';

    };
}
