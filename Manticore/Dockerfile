# This Dockerfile was based on one created by Kavon Faradin
# for his PLDI 2020 submission's artifact.
# See https://gitlab.com/kavon1/manticore/commits/pldi20

FROM fedora:32

# grab all dependencies
RUN dnf upgrade -y \
    && dnf install -y --nodocs \
       # ordinary manticore dependencies
       git \
       gcc \
       gcc-c++ \
       autoconf \
       automake \
       make \
       jemalloc-devel \
       libgomp \
       \
       # for SML/NJ download & build
       glibc-devel.i686 glibc-devel glibc-static.i686 glibc-static wget \
       \
       # llvm dependencies
       cmake \
       zlib \
       \
       # Dependencies introduced by me
       hyperfine \
       patch \
       \
       # MLton dependencies
       gmp-devel \
       bzip2 \
       gzip \
       \
    && rm -rf /var/lib/apt/lists/* \
    && dnf autoremove \
    && dnf clean all
    
# download SML/NJ
RUN mkdir -p /usr/smlnj \
    && cd /usr \
    && wget --no-check-certificate https://smlnj.cs.uchicago.edu/dist/working/110.98.1/config.tgz \
    && cp config.tgz smlnj \

# build & install SML/NJ 32-bit to user's default path to build manticore.
# it's assumed that the SML/NJ config.tgz is already in the directory.
    && cd /usr/smlnj \
    && tar xf config.tgz \
    && rm config.tgz \
    && ./config/install.sh -default 32 \
    && cd /usr/bin \
    && ln -s /usr/smlnj/bin/* ./

# Download Manticore, and set the HEAD to a specific commit (for future consistency)
RUN cd /usr \
    && git clone https://github.com/ManticoreProject/manticore.git --branch=pldi20 \
    && mv manticore pmlc \
    && cd /usr/pmlc \
    # Download the benchmarks suite, which seems to contain some important files separate to the main Manticore repo for some reason
    && git clone https://github.com/ManticoreProject/benchmark.git \
    && cd /usr/pmlc/benchmark \
    # Ensure that the container is pegged to a particular version of the benchmarks
    && git checkout d33a51918db591a57ff096169020c000bb240786
    

# set the working directory
WORKDIR /usr/pmlc
    
# Grab LLVM, as per Manticore build instructions
RUN cd /usr/pmlc \
    && git submodule init llvm/src \
    && git submodule update llvm/src \
    && git submodule init src/lib/basis \
    && git submodule update src/lib/basis \

# build LLVM (with asserts on for testing, since compile time is not important)
    && ./llvm/fresh-build.sh docker \
    && rm -rf llvm/build llvm/src \
    && cd /usr/bin \
    && ln -s /usr/pmlc/llvm/install/bin/* ./

# Peform a small patching, which is necessary now since something has become a compiler warning
RUN echo -e "28c28\n<     strncpy(buf, lab, n);\n---\n>     memcpy(buf, lab, n);" > memcpy.patch \
    && patch /usr/pmlc/src/lib/parallel-rt/config/crc.h memcpy.patch \
    && cat /usr/pmlc/src/lib/parallel-rt/config/crc.h \

# build manticore
    && cd /usr/pmlc \
    && autoheader -Iconfig \
    && autoconf -Iconfig \
    && ./configure --with-llvm=./llvm/install \
    && make local-install \
    && cd /usr/bin \
    && ln -s /usr/pmlc/bin/* ./
