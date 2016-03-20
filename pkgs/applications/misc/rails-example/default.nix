{ stdenv, lib, bundler, fetchFromGitHub, bundlerEnv, defaultGemConfig, libiconv, ruby
, tzdata, git, nodejs, procps
}:

let
  env = bundlerEnv {
    name = "rails-example";
    inherit ruby;
    gemfile = ./Gemfile;
    lockfile = ./Gemfile.lock;
    gemset = ./gemset.nix;
    meta = with lib; {
      homepage = http://www.example.com/;
      platforms = platforms.linux;
      maintainers = [ ];
      license = licenses.mit;
    };
  };

in

stdenv.mkDerivation rec {
  name = "rails-example-${version}";
  version = "1.0.0";

  buildInputs = [ ruby bundler tzdata git nodejs procps ];

  src = fetchFromGitHub {
    owner = "swistak35";
    repo = "nixos-rails-example";
    rev = "48b99875aef6f844ea7f509d80dc0424f0b519fd";
    sha256 = "09d9q460q91793p9crrfzdk8p7bx4mi8bag7f9waac6nrz1qf9km";
  };

  buildPhase = ''
    cat > config/unicorn.rb <<EOF
      app_dir = File.expand_path("../..", __FILE__)
      shared_dir = "/var/lib/rails-example"
      working_directory app_dir

      # Set unicorn options
      worker_processes 2
      preload_app true
      timeout 30

      # Set up socket location
      # listen "#{shared_dir}/sockets/unicorn.sock", :backlog => 64
      listen "127.0.0.1:3333"

      # Logging
      stderr_path "#{shared_dir}/unicorn.stderr.log"
      stdout_path "#{shared_dir}/unicorn.stdout.log"

      # Set master PID location
      pid "#{shared_dir}/unicorn.pid"
    EOF

    cat > config/database.yml <<EOF
    production:
      adapter: postgresql
      database: rails-example_production
      host: localhost
      username: rails-example_production
      password: password123
      encoding: utf8
    EOF
  '';

  installPhase = ''
    cp -r . $out
    rm -rf $out/bin
  '';

  inherit env;
  inherit ruby;

  passthru = {
    inherit env;
    inherit ruby;
  };
}

