{ nixpkgs   ? import ./nixpkgs.nix # nix package set we're using
, profiling ? false # Whether or not to enable library profiling (applies to project components only)
, haddocks  ? false # Whether or not to enable haddock building (applies to project components only)
}:

with rec {
  compiler = "ghc865";

  overlay = import ./overlay.nix { inherit profiling haddocks; };

  pkgs = import nixpkgs {
    config = {
      allowUnfree = false;
      allowBroken = false;
    };
    overlays = [ overlay ];
  };

  make = name: pkgs.haskell.packages.${compiler}.${name};

  librdkafka = make "librdkafka";
};

rec {
  inherit pkgs;
  inherit nixpkgs;
  inherit librdkafka;
}
