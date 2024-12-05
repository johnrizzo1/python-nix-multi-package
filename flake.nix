{
  # This example flake.nix is pretty generic and the same for all
  # examples, except when they define devShells or extra packages.
  description = "Dream2nix example flake";

  # We import the latest commit of dream2nix main branch and instruct nix to
  # re-use the nixpkgs revision referenced by dream2nix.
  # This is what we test in CI with, but you can generally refer to any
  # recent nixpkgs commit here.
  inputs = {
    dream2nix.url = "github:nix-community/dream2nix";
    nixpkgs.follows = "dream2nix/nixpkgs";
  };

  outputs = {
    self,
    dream2nix,
    nixpkgs,
  }: let
    # A helper that helps us define the attributes below for
    # all systems we care about.
    eachSystem = nixpkgs.lib.genAttrs [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-darwin"
      "x86_64-linux"
    ];
  in {
#    packages = eachSystem (system: {
#        # For each system, we define our default package
#      # by passing in our desired nixpkgs revision plus
#      # any dream2nix modules needed by it.
#      default = dream2nix.lib.evalModules {
#        packageSets.nixpkgs = nixpkgs.legacyPackages.${system};
#        modules = [
#          # Import our actual package definiton as a dream2nix module from ./default.nix
##          ./default.nix
#          {
#            # Aid dream2nix to find the project root. This setup should also works for mono
#            # repos. If you only have a single project, the defaults should be good enough.
#            paths.projectRoot = ./.;
#            # can be changed to ".git" or "flake.nix" to get rid of .project-root
#            paths.projectRootFile = "flake.nix";
##            paths.package = ./.;
#            paths.packagesDir = ./packages;
#          }
#        ];
#      };
#    });

    packages = eachSystem (system:
      dream2nix.lib.importPackages {
        projectRoot = ./.;
        projectRootFile = "flake.nix";
        packagesDir = ./packages;
        packageSets.nixpkgs = nixpkgs.legacyPackages.${system};
      }
    );

    devShells = eachSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      packages = self.packages.${system};
      subpkg1 = packages.subpkg1;
      subpkg2 = packages.subpkg2;
      pillow = packages.pillow;
      hello = packages.hello;
      python = packages.subpkg1.config.deps.python;
    in {
      default = pkgs.mkShell {
        inputsFrom = [subpkg1.devShell subpkg2.devShell]; # inherit from the dream2nix generated dev shell
        packages = with pkgs; [
          poetry
          (python.withPackages (pkgs-python: with pkgs-python; [
            ipython
            pillow
            subpkg2
            hello
          ]))
        ];
      };
    });

  };
}