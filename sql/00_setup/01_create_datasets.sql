
CREATE SCHEMA IF NOT EXISTS `your-project-id.olist_raw`
OPTIONS (
  description = 'Raw layer: Data as-is dari CSV files Olist. Tidak ada transformasi. Source of truth.',
  location = 'US'
);

CREATE SCHEMA IF NOT EXISTS `your-project-id.olist_staging`
OPTIONS (
  description = 'Staging layer: View-based cleaning. Standardisasi, cast, null handling.',
  location = 'US'
);

CREATE SCHEMA IF NOT EXISTS `your-project-id.olist_intermediate`
OPTIONS (
  description = 'Intermediate layer: Joined & enriched tables dengan business logic dasar.',
  location = 'US'
);

CREATE SCHEMA IF NOT EXISTS `your-project-id.olist_mart`
OPTIONS (
  description = 'Mart layer: Star Schema — Fact & Dimension tables untuk analisis.',
  location = 'US'
);

CREATE SCHEMA IF NOT EXISTS `your-project-id.olist_reporting`
OPTIONS (
  description = 'Reporting layer: Pre-aggregated tables untuk Power BI DirectQuery.',
  location = 'US'
);