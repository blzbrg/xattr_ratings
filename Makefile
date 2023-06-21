lister: lister.zig
	mkdir -p build && cd build && zig build-exe -freference-trace --library c --library-directory /usr/lib --library attr ../lister.zig

clean:
	rm -r build
