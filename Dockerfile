# syntax=docker/dockerfile:1
# (the syntax directive only works on the very first line)

# 2026-11-18: current versions of everything, pinned: Ruby 4.0.9 and Alpine 3.24 (base image tag), Rails 8.1 and all
# gems (src/Gemfile.lock), R 4.6.0 (apk) with every R package at a fixed version (R/install_packages.R), and the same
# PLINK2 build as the precomputed DGRP3 GWAS (v2.0.0-b.1.4, 7 Nov 2026; checksum below).
FROM ruby:4.0.9-alpine3.24

# R is pinned to 4.6.0 (any Alpine revision of it); the other system packages follow Alpine 3.24
RUN apk add --no-cache R~4.6.0 \
    R-dev~4.6.0 \
    build-base \
    gcc \
    g++ \
    gfortran \
    make \
    cmake \
    bash \
    git \
    libxml2-dev \
    openssl-dev \
    libcurl \
    curl-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    libxt-dev \
    openblas-dev \
    cairo-dev \
    pango-dev \
    gdk-pixbuf-dev \
    musl-dev \
    yaml-dev \
    postgresql-dev nodejs npm yarn busybox-extras curl wget openjdk8-jre less gzip unzip

# Alpine builds R packages with -flto, which fails with GCC 15 and Alpine's fortify headers ("inlining failed in call
# to 'always_inline' 'vsnprintf'", e.g. for Deriv, needed by car): compile R packages without LTO.
RUN printf '%s\n' 'CFLAGS += -fno-lto' 'CXXFLAGS += -fno-lto' 'CXX11FLAGS += -fno-lto' 'CXX14FLAGS += -fno-lto' \
      'CXX17FLAGS += -fno-lto' 'CXX20FLAGS += -fno-lto' 'CXX23FLAGS += -fno-lto' 'FFLAGS += -fno-lto' 'FCFLAGS += -fno-lto' \
      'LDFLAGS += -fno-lto' > "$(R RHOME)/etc/Makevars.site"

# R packages: all pinned, dependencies included, installed from source tarballs at the exact version (CRAN, Bioconductor
# 3.23), in dependency order; the build stops on any failure (R/install_packages.R, same approach as asap_run)
COPY R/install_packages.R /tmp/install_packages.R
RUN Rscript /tmp/install_packages.R && rm /tmp/install_packages.R

# Verify R installation
RUN R --version && Rscript -e "for (p in c('data.table', 'stringr', 'ramwas', 'car', 'rstatix', 'Cairo', 'jsonlite')) cat(p, as.character(packageVersion(p)), '\n')"

# PLINK2: the exact build used for the precomputed DGRP3 GWAS (PLINK v2.0.0-b.1.4LM AVX2 Intel, 7 Nov 2026).
# The zip's checksum is checked; its plink2 has sha256 2d6db9e9770266ffafccef26945f653c0fa9d5307719b2cbd98626dc8851d8dd.
# This build needs a CPU with AVX2 (the DGRPool VM has it, checked 2026-11-18). On a CPU without AVX2, `plink2 --version`
# fails below: use the generic build of the same version instead,
# https://s3.amazonaws.com/plink2-assets/beta1/plink2_linux_x86_64_20261107.zip
# (zip sha256 16b5cf92faed7e8b8aa1010c6eab9bac17c92b57ccfa69c4d059b1b17b98eb70).
ENV PLINK2_URL="https://s3.amazonaws.com/plink2-assets/beta1/plink2_linux_avx2_20261107.zip"
ENV PLINK2_ZIP_SHA256="361afa4e9062147c2770eccc2b61684b37950833f64e61c09fee10f36433268a"

# Download and install plink2 (only the plink2 binary from the zip)
RUN mkdir -p /opt/plink2 && \
    wget -q ${PLINK2_URL} -O /opt/plink2/plink2.zip && \
    echo "${PLINK2_ZIP_SHA256}  /opt/plink2/plink2.zip" | sha256sum -c - && \
    unzip -j /opt/plink2/plink2.zip plink2 -d /opt/plink2 && \
    chmod +x /opt/plink2/plink2 && \
    rm /opt/plink2/plink2.zip

# Add plink2 to the PATH
ENV PATH="/opt/plink2:${PATH}"

# Test if plink2 is installed (and runs on this CPU)
RUN plink2 --version

RUN mkdir -p /opt/mimemagic
WORKDIR /opt/dgrpool
ENV FREEDESKTOP_MIME_TYPES_PATH=/opt/mimemagic

# Copy the lockfile too, so the image gets exactly the gem versions the app expects
COPY src/Gemfile src/Gemfile.lock ./
RUN bundle install
COPY src/. .
# (the former CMD ["rm ./tmp/pids/server.pid"] was always overridden by the last CMD; start.sh removes the pid file)

# Add health check script
COPY healthcheck.sh ./

# Set execute permissions
RUN chmod +x /opt/dgrpool/healthcheck.sh

# Define health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 CMD /opt/dgrpool/healthcheck.sh || exit 1

# Start solr server, esbuild and scss builders and puma server
CMD ["sh", "start.sh"]
