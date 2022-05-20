{ pkgs }: {
	deps = [
        pkgs.ruby_3_1
        pkgs.rubyPackages_3_1.solargraph
        pkgs.rufo
        pkgs.sqlite
        pkgs.postgresql_13
	];
}
