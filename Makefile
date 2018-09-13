.PHONY: build doc install uninstall clean

build:
	dune build @install
	[ -e bin ] || ln -s _build/install/default/bin bin
	[ -e lib ] || ln -s _build/install/default/lib lib

doc:
	dune build @doc
	[ -e doc ] || ln -s _build/default/_doc/_html/ doc

install:
	dune install

uninstall:
	dune uninstall

clean:
	dune clean
	rm -f bin lib doc
