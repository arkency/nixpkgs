{ stdenv, fetchurl, makeWrapper, coreutils, git, openssh, bash, gnused, gnugrep }:

stdenv.mkDerivation rec {
  name = "buildkite-agent-2.1.6.1";

  src = fetchurl {
    url = "https://github.com/buildkite/agent/releases/download/v2.1.6.1/buildkite-agent-linux-386-2.1.6.1.tar.gz";
    sha256 = "6ee24c25755773362e62324d96ab9fe1ea22c953865b7f8060033a97b8cb0e7a";
  };

  buildInputs = [ makeWrapper ];
  phases = "unpackPhase installPhase";
  sourceRoot = ".";
  installPhase = ''
    installBin buildkite-agent

    mkdir -p $out/share
    mv hooks bootstrap.sh $out/share/

    patchShebangs $out/share/

    substituteInPlace $out/share/bootstrap.sh \
      --replace "#!/bin/bash" "#!$(type -P bash)"

    wrapProgram $out/bin/buildkite-agent \
      --set PATH '"${openssh}/bin/:${git}/bin:${coreutils}/bin:${gnused}/bin:${gnugrep}/bin:$PATH"'
  '';

  meta = {
    description = "Build runner for buildkite.com";
    longDescription = ''
      The buildkite-agent is a small, reliable, and cross-platform build runner that makes it easy to run automated builds on your own infrastructure. It’s main responsibilities are polling buildkite.com for work, running build jobs, reporting back the status code and output log of the job, and uploading the job's artifacts.
    '';
    homepage = https://buildkite.com/docs/agent;
    license = stdenv.lib.licenses.mit;
    platforms = stdenv.lib.platforms.linux;
  };
}
