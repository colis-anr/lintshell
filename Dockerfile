ARG TAG=latest
ARG IMAGE=ocaml/opam2:$TAG
FROM $IMAGE

MAINTAINER Nicolas Jeannerod

ARG SWITCH=
RUN [ -z "$SWITCH" ] || opam switch create "$SWITCH"

WORKDIR /home/opam/workdir

RUN sudo apt-get install -y m4

COPY *.opam .
RUN sudo chown -R opam .
RUN opam install . --deps-only

COPY . .
RUN sudo chown -R opam .
RUN eval $(opam env) && make
