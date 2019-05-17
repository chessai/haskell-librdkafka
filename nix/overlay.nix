{ profiling, haddocks }:

self: super:

with rec {
  inherit (super) lib;

  hlib = super.haskell.lib;

  # This function removes any cruft not relevant to our Haskell builds.
  #
  # If something irrelevant to our build is not removed by this function, and
  # you modify that file, Nix will rebuild the derivation even though nothing
  # that would affect the output has changed.
  #
  # The `excludePred` argument is a function that can be used to filter out more
  # files on a package-by-package basis.
  # The `includePred` argument is a function that can be used to include files
  # that this function would normally filter out.
  clean = (
    { path,
      excludePred ? (name: type: false),
      includePred ? (name: type: false)
    }:
    if lib.canCleanSource path
    then lib.cleanSourceWith {
           filter = name: type: (includePred name type) || !(
             with rec {
               baseName     = baseNameOf (toString name);
               isFile       = (type == "regular");
               isLink       = (type == "symlink");
               isDir        = (type == "directory");
               isUnknown    = (type == "unknown");
               isNamed      = str: (baseName == str);
               hasExtension = ext: (lib.hasSuffix ext baseName);
               beginsWith   = pre: (lib.hasPrefix pre baseName);
               matches      = regex: (builtins.match regex baseName != null);
             };

             lib.any (lib.all (x: x)) [
               # Each element of this list is a list of booleans, which should be
               # thought of as a "predicate" on paths; the predicate is true if the
               # list is composed entirely of true values.
               #
               # If any of these predicates is true, then the path will not be
               # included in the source used by the Nix build.
               #
               # Remember to use parentheses around elements of a list;
               # `[ f x ]`   is a heterogeneous list with two elements,
               # `[ (f x) ]` is a homogeneous list with one element.
               # Knowing the difference might save your life.
               [ (excludePred name type) ]
               [ isUnknown ]
               [ isDir (isNamed "dist") ]
               [ isDir (isNamed "dist-newstyle") ]
               [ isDir (isNamed  "run") ]
               [ (isFile || isLink) (hasExtension ".nix") ]
               [ (beginsWith ".ghc") ]
               [ (hasExtension ".sh") ]
               [ (hasExtension ".txt") ]
             ]);
           src = lib.cleanSource path;
         }
    else path);

  mainOverlay = hself: hsuper: {
    callC2N = (
      { name,
        path                  ? (throw "callC2N requires path argument!"),
        rawPath               ? (clean { inherit path; }),
        relativePath          ? null,
        args                  ? {},
        apply                 ? [],
        extraCabal2nixOptions ? []
      }:

      with rec {
        filter = p: type: (
          (super.lib.hasSuffix "${name}.cabal" p)
          || (baseNameOf p == "package.yaml"));
        expr = hsuper.haskellSrc2nix {
          inherit name;
          extraCabal2nixOptions = self.lib.concatStringsSep " " (
            (if relativePath == null then [] else ["--subpath" relativePath])
            ++ extraCabal2nixOptions);
          src = if super.lib.canCleanSource rawPath
                then super.lib.cleanSourceWith { src = rawPath; inherit filter; }
                else rawPath;
        };
        compose = f: g: x: f (g x);
        composeList = x: lib.foldl' compose lib.id x;
      };

      composeList apply
      (hlib.overrideCabal
       (hself.callPackage expr args)
       (orig: { src = rawPath; })));

    librdkafka = hself.callC2N {
      name = "librdkafka";
      path = ../.;
      apply = [ hlib.dontCheck ]
        ++ ( if profiling
             then [ hlib.enableLibraryProfiling hlib.enableExecutableProfiling ]
             else [ hlib.disableLibraryProfiling hlib.disableExecutableProfiling ]
           )
        ++ ( if haddocks
             then [ hlib.doHaddock ]
             else [ hlib.dontHaddock ]
           );
    };
  };

  composeOverlayList = lib.foldl' lib.composeExtensions (_: _: {});

  overlay = composeOverlayList [
    mainOverlay
  ];

};

{
  haskell = super.haskell // {
    packages = super.haskell.packages // {
      ghc844 = (super.haskell.packages.ghc844.override {
        overrides = super.lib.composeExtensions
          (super.haskell.packageOverrides or (self: super: {}))
          overlay;
      });
      ghc864 = (super.haskell.packages.ghc864.override {
        overrides = super.lib.composeExtensions
          (super.haskell.packageOverrides or (self: super: {}))
          overlay;
      });
      ghc865 = (super.haskell.packages.ghc865.override {
        overrides = super.lib.composeExtensions
          (super.haskell.packageOverrides or (self: super: {}))
          overlay;
      });
    };
  };

}
