# R packages of the dgrpool_web image, all pinned (made 2026-11-18 for R 4.6.0 / Bioconductor 3.23).
# Every package, dependencies included (138: 115 CRAN, 23 Bioconductor), is installed from its source tarball at
# the exact version, in dependency order; the build stops if a download, a build or the version check fails.
# The helper functions are those of DeplanckeLab/asap_run (R/packages/install_packages.v8.2.R).
# Packages used directly by the app: data.table, jsonlite, stringr, ramwas, car, rstatix, Cairo (src/lib/*.R).
# To update: change the versions here (a newer version must keep the dependency order valid), rebuild, check the log.

# Compile options
if (!nzchar(Sys.getenv("MAKEFLAGS"))) Sys.setenv(MAKEFLAGS = "-j4")

# Functions
install_and_verify <- function(pkgfile, package, version) {
  install.packages(pkgfile, repos = NULL, type = "source", verbose = FALSE, quiet = T)
  if (!requireNamespace(package, quietly = TRUE)) {
	message("Package ",package," failed installation")
	quit(status = 1)
  }
  # A failed build only warns and can leave another copy in place (e.g. Matrix/MASS bundled with R): check the version
  installed <- as.character(utils::packageVersion(package))
  if (package_version(installed) != package_version(version)) {
	message("Package ", package, " v", version, " failed installation (found v", installed, " instead)")
	quit(status = 1)
  }
}

install.cran <- function(package, version, host="cran.r-project.org") {
  main_url <- paste0("https://", host, "/src/contrib/", package, "_", version, ".tar.gz")
  archive_url <- paste0("https://", host, "/src/contrib/Archive/", package, "/", package, "_", version, ".tar.gz")
 
  tmp_file <- tempfile(fileext = ".tar.gz")

  tryCatch({
      message("Installing ", package," v", version," from main CRAN repository...", appendLF = FALSE)
      suppressWarnings(download.file(main_url, tmp_file, mode = "wb", quiet = TRUE))
      install_and_verify(tmp_file, package, version)
      unlink(tmp_file)
    }, error = function(e) {
      message("\t[FAILED - RETRY] ", e$message)
      message("Trying to install ", package," v", version," from CRAN archive...", appendLF = FALSE)
      tryCatch({
          suppressWarnings(download.file(archive_url, tmp_file, mode = "wb", quiet = TRUE))
          install_and_verify(tmp_file, package, version)
          unlink(tmp_file)
        }, error = function(e) {
          message("\t[FAILED - EXIT] ", e$message)
		  message("Both installation attempts of ", package," v", version, " failed. Stopping installation.")
		  quit(status = 1)
        })
    })
	message("\t[SUCCESS]")
}

install.bioconductor <- function(package, version, bioconductor_version, source = "bioc") {
  main_url      <- paste0("https://www.bioconductor.org/packages/release/", source, "/src/contrib/", package, "_", version, ".tar.gz")
  archive_url 	<- paste0("https://www.bioconductor.org/packages/", bioconductor_version, "/", source, "/src/contrib/", package, "_", version, ".tar.gz")
  archive_url_2	<- paste0("https://www.bioconductor.org/packages/", bioconductor_version, "/", source, "/src/contrib/Archive/", package, "/", package, "_", version, ".tar.gz")
  
  tmp_file <- tempfile(fileext = ".tar.gz")
  tryCatch({
      message("Installing ", package, " v", version, " from Bioconductor archive...", appendLF = FALSE)
      suppressWarnings(download.file(archive_url, tmp_file, mode = "wb", quiet = TRUE))
      install_and_verify(tmp_file, package, version)
      unlink(tmp_file)
    }, error = function(e) {
      message("\t[FAILED - RETRY] ", e$message)
      message("Trying to install ", package, " v", version, " from main Bioconductor repository...", appendLF = FALSE)
      tryCatch({
          suppressWarnings(download.file(main_url, tmp_file, mode = "wb", quiet = TRUE))
          install_and_verify(tmp_file, package, version)
          unlink(tmp_file)
        }, error = function(e) {
          message("\t[FAILED - RETRY] ", e$message)
          message("Trying to install ", package, " v", version, " from Bioconductor archive 2...", appendLF = FALSE)
          tryCatch({
              suppressWarnings(download.file(archive_url_2, tmp_file, mode = "wb", quiet = TRUE))
              install_and_verify(tmp_file, package, version)
              unlink(tmp_file)
            }, error = function(e) {
              message("\t[FAILED - EXIT] ", e$message)
              message("All three installation attempts of ", package, " v", version, " failed. Stopping installation.")
              quit(status = 1)
            })
        })
    })
  message("\t[SUCCESS]")
}


# Packages, in dependency order (CRAN and Bioconductor 3.23)
install.cran("BH", version="1.90.0-1")
install.cran("Cairo", version="1.7-0") # web GWAS: PDF plots
install.cran("DBI", version="1.3.0")
install.cran("Formula", version="1.2-6")
install.cran("KernSmooth", version="2.23-27")
install.cran("MASS", version="7.3-66")
install.cran("R.methodsS3", version="1.8.2")
install.cran("R6", version="2.6.1")
install.cran("RColorBrewer", version="1.1-3")
install.cran("Rcpp", version="1.1.2")
install.bioconductor("Rhtslib", version="3.8.0", "3.23")
install.cran("S7", version="0.2.2")
install.cran("SparseM", version="1.84-2")
install.cran("abind", version="1.4-8")
install.cran("backports", version="1.5.1")
install.cran("bit", version="4.6.0")
install.cran("bitops", version="1.1-0")
install.cran("boot", version="1.3-32")
install.cran("carData", version="3.0-6")
install.cran("cli", version="3.6.6")
install.cran("codetools", version="0.2-20")
install.cran("colorspace", version="2.1-4")
install.cran("corrplot", version="0.95")
install.cran("cpp11", version="0.5.5")
install.cran("crayon", version="1.5.3")
install.cran("curl", version="8.1.0")
install.cran("data.table", version="1.18.6.1") # web GWAS (running_GWAS_user.R) and correlation.R
install.cran("digest", version="0.6.39")
install.cran("farver", version="2.1.2")
install.cran("fastmap", version="1.2.0")
install.cran("filelock", version="1.0.3")
install.cran("filematrix", version="1.3")
install.cran("formatR", version="1.14")
install.cran("fracdiff", version="1.5-4")
install.cran("futile.options", version="1.0.1")
install.cran("generics", version="0.1.4")
install.cran("glue", version="1.8.1")
install.cran("iterators", version="1.0.14")
install.cran("jsonlite", version="2.0.0") # web GWAS and correlation.R
install.cran("labeling", version="0.4.3")
install.cran("lattice", version="0.23-1") # kept from the previous Dockerfile
install.cran("magrittr", version="2.0.5")
install.cran("matrixStats", version="1.5.0")
install.cran("mime", version="0.13")
install.cran("nloptr", version="2.2.1")
install.cran("nnet", version="7.3-21")
install.cran("numDeriv", version="2016.8-1.1")
install.cran("pkgconfig", version="2.0.3")
install.cran("png", version="0.1-9")
install.cran("prettyunits", version="1.2.0")
install.cran("rbibutils", version="2.4.1")
install.cran("rlang", version="1.3.0")
install.cran("shape", version="1.4.6.1")
install.cran("snow", version="0.4-4")
install.cran("stringi", version="1.8.9")
install.cran("sys", version="3.4.3")
install.cran("timeDate", version="4052.112")
install.cran("utf8", version="1.2.6")
install.cran("viridisLite", version="0.4.3")
install.cran("withr", version="3.0.3")
install.bioconductor("BiocGenerics", version="0.58.1", "3.23")
install.cran("Deriv", version="4.3.6")
install.cran("Matrix", version="1.7-6")
install.bioconductor("MatrixGenerics", version="1.24.0", "3.23")
install.cran("R.oo", version="1.27.1")
install.cran("RcppArmadillo", version="15.6.2-1")
install.cran("RcppEigen", version="0.3.4.0.2")
install.cran("Rdpack", version="2.6.6")
install.cran("askpass", version="1.2.1")
install.cran("bit64", version="4.8.6")
install.cran("cachem", version="1.1.0")
install.cran("foreach", version="1.5.2")
install.cran("isoband", version="0.3.0")
install.cran("lambda.r", version="1.2.6")
install.cran("lifecycle", version="1.0.5")
install.cran("minqa", version="1.2.8")
install.cran("nlme", version="3.1-172")
install.cran("xml2", version="1.6.0")
install.cran("zoo", version="1.9-1")
install.bioconductor("Biobase", version="2.72.0", "3.23")
install.cran("MatrixModels", version="0.5-4") # kept from the previous Dockerfile
install.cran("R.utils", version="2.13.0") # fread of .gz files
install.bioconductor("S4Vectors", version="0.50.3", "3.23")
install.cran("futile.logger", version="1.4.9")
install.cran("gtable", version="0.3.6")
install.cran("lmtest", version="0.9-40")
install.cran("memoise", version="2.0.1")
install.cran("mgcv", version="1.9-5")
install.cran("openssl", version="2.6.0")
install.cran("reformulas", version="0.4.4")
install.cran("scales", version="1.4.0")
install.cran("survival", version="3.8-12")
install.cran("urca", version="1.3-4")
install.cran("vctrs", version="0.7.3")
install.bioconductor("BiocParallel", version="1.46.0", "3.23")
install.bioconductor("IRanges", version="2.46.0", "3.23")
install.cran("blob", version="1.3.0")
install.cran("ggplot2", version="4.0.4")
install.cran("glmnet", version="5.2")
install.cran("hms", version="1.1.4")
install.cran("httr", version="1.4.9")
install.cran("httr2", version="1.3.0")
install.cran("lme4", version="2.1-0")
install.cran("pillar", version="1.11.1")
install.cran("purrr", version="1.2.2")
install.cran("quantreg", version="6.1") # kept from the previous Dockerfile
install.cran("stringr", version="1.6.0") # web GWAS
install.cran("tidyselect", version="1.2.1")
install.cran("RSQLite", version="3.53.3")
install.bioconductor("S4Arrays", version="1.12.1", "3.23")
install.bioconductor("Seqinfo", version="1.2.0", "3.23")
install.bioconductor("XVector", version="0.52.0", "3.23")
install.cran("cowplot", version="1.2.0")
install.cran("forecast", version="9.0.2")
install.cran("progress", version="1.2.3")
install.cran("tibble", version="3.3.1")
install.bioconductor("Biostrings", version="2.80.2", "3.23")
install.bioconductor("GenomicRanges", version="1.64.0", "3.23")
install.bioconductor("SparseArray", version="1.12.3", "3.23")
install.cran("dplyr", version="1.2.1")
install.bioconductor("DelayedArray", version="0.38.2", "3.23")
install.bioconductor("KEGGREST", version="1.52.2", "3.23")
install.bioconductor("Rsamtools", version="2.28.0", "3.23")
install.bioconductor("cigarillo", version="1.2.1", "3.23")
install.cran("tidyr", version="1.3.2")
install.bioconductor("AnnotationDbi", version="1.74.0", "3.23")
install.bioconductor("SummarizedExperiment", version="1.42.0", "3.23")
install.cran("broom", version="1.0.13")
install.cran("dbplyr", version="2.6.0")
install.bioconductor("BiocFileCache", version="3.2.0", "3.23")
install.bioconductor("GenomicAlignments", version="1.48.0", "3.23")
install.cran("modelr", version="0.1.11")
install.bioconductor("biomaRt", version="2.68.6", "3.23")
install.cran("doBy", version="4.7.2")
install.cran("pbkrtest", version="0.5.5")
install.bioconductor("ramwas", version="1.36.0", "3.23") # web GWAS: QQ and Manhattan plots
install.cran("car", version="3.1-5") # web GWAS: covariate ANOVA
install.cran("rstatix", version="1.1.0") # web GWAS: Shapiro test
