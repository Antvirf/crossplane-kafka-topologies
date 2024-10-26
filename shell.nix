let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-23.11";
  pkgs = import nixpkgs { config = {allowUnfree = true;}; overlays = []; };
in

pkgs.mkShellNoCC {
  packages = with pkgs; [
    kubectl
    k3d
    k9s
    kubernetes-helm
  ];
shellHook = ''
'';
}
