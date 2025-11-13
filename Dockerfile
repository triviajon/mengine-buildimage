# Use Ubuntu as base
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LEAN_VERSION=leanprover/lean4:nightly
ENV ELAN_HOME=/usr/local/elan

# Install Python3, clang, Coq, and Lean
RUN apt-get update && apt-get install -y \
    git python3 python3-pip clang make build-essential curl unzip \
    opam \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y libgmp-dev pkg-config && \
    opam init -y --disable-sandboxing && \
    opam switch create coq 4.09.1 && \
    eval $(opam env) && \
    opam install -y coq.8.19.0

ENV PATH="/root/.opam/coq/bin:${PATH}"
ENV PATH=/usr/local/elan/bin:$PATH

RUN curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | \
    sh -s -- -y --no-modify-path --default-toolchain $LEAN_VERSION && \
    chmod -R a+w $ELAN_HOME && \
    elan --version && \
    lean --version && \
    leanc --version && \
    lake --version

# Clone repositories and build
WORKDIR /root/foss
RUN git clone https://github.com/triviajon/mengine.git && \
    git clone https://github.com/triviajon/mengine-benchmarks.git && \
    git clone https://github.com/mit-plv/coqutil.git

ENV PATH="/root/.opam/default/bin:${PATH}"
RUN echo 'eval $(opam env)' >> /root/.bashrc

WORKDIR /root/foss/coqutil
RUN make

WORKDIR /root/foss/mengine
RUN sed -i 's/-march=native//g' Makefile && make

# Modify benchmark config
WORKDIR /root/foss/mengine-benchmarks
RUN sed -i 's|"mengine_path":.*|"mengine_path": "/root/foss/mengine/main",|' config.json && \
    sed -i 's|"coqc_path":.*|"coqc_path": "coqc",|' config.json && \
    sed -i 's|"lean_path":.*|"lean_path": "lean",|' config.json && \
    sed -i 's|"coqutil_root_path":.*|"coqutil_root_path": "/root/foss/coqutil",|' config.json

WORKDIR /root/foss/mengine-benchmarks
RUN rm -f */results.json || true
CMD bash -c "eval \$(opam env) && python3 benchmark.py run && python3 benchmark.py plot"

