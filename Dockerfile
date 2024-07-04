# Use the Docker image format
# syntax=docker/dockerfile:1

FROM ruby:3.1.2-alpine

RUN apk add  R \
    R-dev \
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
    openblas-dev\
    postgresql-dev git build-base nodejs npm yarn busybox-extras curl wget openjdk8-jre less gzip unzip

RUN echo 'toto'

# Install lattice from CRAN
RUN Rscript -e "install.packages('lattice', repos='https://cloud.r-project.org')"

# Install MASS and Matrix from CRAN archive
RUN Rscript -e "install.packages('https://cran.r-project.org/src/contrib/Archive/MASS/MASS_7.3-55.tar.gz', repos=NULL, type='source')"
RUN Rscript -e "install.packages('https://cran.r-project.org/src/contrib/Archive/Matrix/Matrix_1.4-0.tar.gz', repos=NULL, type='source')"

# Install MatrixModels from CRAN archive
RUN Rscript -e "install.packages('https://cran.r-project.org/src/contrib/Archive/MatrixModels/MatrixModels_0.4-1.tar.gz', repos=NULL, type='source')"

RUN Rscript -e "install.packages(c('quantreg', 'data.table', 'jsonlite', 'car', 'rstatix'), repos='http://stat.ethz.ch/CRAN/');"

# Install BiocManager if not already installed
RUN Rscript -e "if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager', repos='https://cloud.r-project.org')"

# Install ramwas using BiocManager
RUN Rscript -e "BiocManager::install('ramwas')"

# Install R.utils package
RUN Rscript -e "install.packages('R.utils', repos='https://cloud.r-project.org')"

# Verify R installation
RUN R --version

# Verify Rscript installation
RUN Rscript --version

# Set the PLINK2 version and download URL
#ENV PLINK2_VERSION="2.00a3.3LM"
ENV PLINK2_URL="https://s3.amazonaws.com/plink2-assets/plink2_linux_x86_64_latest.zip"

# Create a directory for plink2
RUN mkdir -p /opt/plink2

# Download and install plink2
RUN wget -q ${PLINK2_URL} -O /opt/plink2/plink2.zip && \
    unzip /opt/plink2/plink2.zip -d /opt/plink2 && \
    chmod +x /opt/plink2/plink2 && \
    rm /opt/plink2/plink2.zip

# Add plink2 to the PATH
ENV PATH="/opt/plink2:${PATH}"

# Test if plink2 is installed
RUN plink2 --version

RUN mkdir -p /opt/mimemagic
WORKDIR /opt/dgrpool
ENV FREEDESKTOP_MIME_TYPES_PATH=/opt/mimemagic
COPY src/Gemfile .
RUN bundle install
COPY src/. .
CMD ["rm ./tmp/pids/server.pid"]

# Add health check script
COPY healthcheck.sh ./

# Set execute permissions
RUN chmod +x /opt/dgrpool/healthcheck.sh

# Define health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 CMD /opt/dgrpool/healthcheck.sh || exit 1

# Start solr server, esbuild and scss builders and puma server
CMD ["sh", "start.sh"]
