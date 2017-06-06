.PHONY: all clean plugins

OCAMLBUILD = ocamlbuild -use-ocamlfind -X plugins -X lib

PLUGINS=\
	plugins/quoting/find

all: plugins
	$(OCAMLBUILD) lintshell.native liblintshell.cma liblintshell.cmxa liblintshell.cmxs
	mkdir -p bin lib
	cp lintshell.native bin/lintshell
	cp _build/src/liblintshell.* lib

plugins:
	mkdir -p lib
	for d in $(PLUGINS); do make -C $$d; cp $$d/_build/*.cm* $$d/_build/*.[oa] lib; done

install:
	@ if [ x$(PREFIX) = x ]; then			\
	  echo ;					\
	  echo Please use the following command:;	\
	  echo;						\
	  echo % PREFIX=... make install;		\
	  echo ;					\
          echo 'to install lintshell at $$PREFIX/bin';	\
	  echo ;					\
	  exit 1;					\
	fi
	cp bin/lintshell $(PREFIX)/bin
	ocamlfind install liblintshell META || true
	cp lib/* _build/src/analyzer.cmi _build/src/analyzer.ml \
            `ocamlfind printconf destdir`/liblintshell

clean:
	for d in $(PLUGINS); do make -C $$d clean; done
	$(OCAMLBUILD) -clean
	[ ! -d bin ] || rm -fr bin
	[ ! -d lib ] || rm -fr lib

