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

DGRPool encourages community participation by allowing users to become curators. Curators help maintain the platform by formatting and validating submitted datasets, ensuring the quality of the data.

### Interactive Data Analysis

Users can perform various analyses including phenotype correlation and GWAS. Pre-calculated GWAS analyses are available for browsing, and users can also upload their own phenotypic data for analysis.

### Proof-of-Concept Studies

DGRPool provides proof-of-concept studies to showcase its potential in facilitating biological discoveries. These studies highlight associations between phenotypes, providing valuable insights for further research.

## Development Server Setup

To set up the development server for DGRPool, follow these steps:

1. **Obtain the Database Dump**: Get the dump file from the database and place it in the `startdb` folder. If the folder doesn't exist, create one.

2. **Create Data Folder**: Ensure there is a `/data` folder in the root directory of the project. If it doesn't exist, create one.

3. **Copy Files**: Copy all files present in `/data/dgrpool` on the DGRPool server to the local `/data` folder. You can use tools like `rsync` for this purpose.

4. **Build Files**: If the files are not built automatically, navigate to the container and run the following commands: 
```bash
   npm run build & npm run build:css
```

## Contributing

DGRPool welcomes contributions from the community. Users interested in becoming curators or contributing to the development of the platform can reach out through the provided contact information on the website.

## Contact

For inquiries or support, please contact the DGRPool team at [dgrpool@gmail.com](mailto:dgrpool@gmail.com)

## License

See LICENSE file

---

By leveraging the power of community-driven curation and interactive data analysis, DGRPool aims to accelerate research in Drosophila genetics and provide a valuable resource for the scientific community.