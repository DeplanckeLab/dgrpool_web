# DGRPool - Drosophila Genetic Reference Panel Phenotyping Web Application

## Overview

DGRPool is a web application designed to serve as a comprehensive repository for Drosophila Genetic Reference Panel (DGRP) phenotyping datasets. It not only provides a centralized hub for accessing existing literature on DGRP phenotyping data but also offers tools for conducting basic systems genetics-inspired analyses. The primary aim of DGRPool is to make DGRP phenotyping data findable, accessible, interoperable, and reusable (FAIR) to facilitate research in the field of Drosophila genetics.

## Features

- **Dataset Repository**: DGRPool acts as a repository for DGRP phenotyping datasets, indexed with relevant keywords and categorized for easy search and access.
- **Community Curated**: Users can become curators, contributing to the maintenance and curation of the datasets, ensuring accuracy and relevance.
- **Interactive Data Analysis**: Users can perform various analyses including phenotype correlation, Genome-Wide Association Studies (GWAS), and Phenome-Wide Association Studies (PheWAS) directly on the platform.
- **User-Submitted Phenotypes**: Researchers can upload their own phenotypic data to the platform for correlation analyses and GWAS, expanding the utility of DGRPool.
- **Proof-of-Concept Studies**: DGRPool showcases its potential through proof-of-concept studies, providing insights into biological discoveries facilitated by the platform.

### Dataset Repository

Users can explore the repository by searching for keywords or browsing through curated categories such as "ageing", "metabolism", or "olfactory". Each study is meticulously curated to ensure data accuracy and relevance.

### Community Curated

DGRPool encourages community participation by allowing users to become curators. If you are interested in becoming a curator, please e-mail us at [bioinfo.epfl@gmail.com](mailto:bioinfo.epfl@gmail.com?subject="Volunteering as a curator"). Curators help maintain the platform by formatting and validating submitted datasets, ensuring the quality of the data.

### Interactive Data Analysis

Users can perform various analyses including phenotype correlation and GWAS. Pre-calculated GWAS analyses are available for browsing, and users can also upload their own phenotypic data for analysis.

### Proof-of-Concept Studies

DGRPool provides proof-of-concept studies to showcase its potential in facilitating biological discoveries. These studies highlight associations between phenotypes, providing valuable insights for further research.

## Contributing

DGRPool welcomes contributions from the community. Users interested in becoming curators or contributing to the development of the platform can reach out through the provided contact information on the [website](https://dgrpool.epfl.ch/).

## Contact

For inquiries or support, please contact the DGRPool team at [bioinfo.epfl@gmail.com](mailto:bioinfo.epfl@gmail.com)

## License

See LICENSE file

## [DGRPool dev team] Development Server Setup

To set up the development server for DGRPool, follow these steps:

1. **Copy Files**:
DGRPool requires two folders:
- **$data**: a data folder, containing GWAS results, GWAS scripts, and other data files. You can put this data folder anywhere on the system (e.g. `/data/dgrpool`)
- **$srv**: a website folder, containing the code on this github page, which will be the anchor point of the Ruby-on-Rails app (e.g. `/srv/dgrpool`)

Then, you need to:
- `git clone` the current repo in the `$srv` folder
- Copy the data files, whether from a cloud storage, or from the current DGRPool server (for DGRPool team) to the `$data` folder. Then create a symlink `data` in the `$srv` folder pointing to it: `ln -s $data $srv/data`
- Get the dump file from a cloud storage, or from the existing database (`pg_dump dgrpool >dgrpool.dump`, for DGRPool team) and place it in the `$srv/startdb` folder (can be gzipped). If the folder doesn't exist, create one.
- Create the `docker-compose.yaml` file with your information (symlink or copy from example file if needed)
- Create the `.env` file with your information (symlink or copy from example file if needed)
  - POSTGRES_PASSWORD is the password for the database (pick any you want for your database)
  - SECRET_KEY_BASE is the secret key (pick any you want)
  - RAILS_ENV should be picked in [development, production]
  - DATA_DIR should be the `$data` directory
  - ACTION_MAILER_HOST is the url of the host website (e.g. dgrpool.epfl.ch)
  - ACTION_MAILER_PORT is the port of the host website (e.g. 3000)

2. **Build Files**:
Run the following command
```bash
   docker-compose build
```

3. **Run the container**:
Run the following command
```bash
   docker-compose up
```

4. **Test the app**:
You need to wait for the database to load completely before you can use the website. I can take a while.
Once it's done, a message will tell you "PostgreSQL init process complete; ready for start up".

Then the database will restart, and the website will be fully available at `yourhost.com:3000` from a web browser.

Check that everything is working out. Then you can stop the Docker, and re-run it in the background.

```bash
   docker-compose down
   docker-compose up -d
```
This runs the Dockerized website in "detached" mode, so everything is handled by the Docker daemon (e.g. restarting in case of abnormal behaviour).
