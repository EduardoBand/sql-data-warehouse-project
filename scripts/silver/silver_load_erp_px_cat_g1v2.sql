/*
====================================================
ETL Script: Load Product Category Data – ERP (Bronze → Silver)
====================================================

Script Purpose:
    Performs a full refresh load of ERP product category data
    into the Silver layer table (silver.erp_px_cat_g1v2).
    The target table is truncated before inserting fresh
    data from the Bronze layer source.

Transformation Logic:
    - Full refresh strategy:
        * Truncates the target Silver table to remove
          existing records.
        * Inserts data from the Bronze layer as-is.

    - Direct load:
        * No data cleansing, normalization, or transformation
          is applied.
        * Source data was assessed as clean and compliant
          with Silver layer requirements.

Source Table:
    bronze.erp_px_cat_g1v2

Target Table:
    silver.erp_px_cat_g1v2
====================================================
*/

PRINT'>> Truncating Table: silver.erp_px_cat_g1v2';
TRUNCATE TABLE silver.erp_px_cat_g1v2
PRINT '>> Inserting Data into silver.erp_px_cat_g1v2';
INSERT INTO silver.erp_px_cat_g1v2 (id,
cat,
subcat,
maintenance)

SELECT
id,
cat,
subcat,
maintenance
FROM bronze.erp_px_cat_g1v2
