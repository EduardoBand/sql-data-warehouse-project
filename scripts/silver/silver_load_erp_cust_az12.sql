/*
====================================================
ETL Script: Transform Customer Data – ERP (Bronze → Silver)
====================================================

Script Purpose:
    Cleans and standardizes ERP customer data from the Bronze layer
    (bronze.erp_cust_az12) before loading it into the Silver layer
    (silver.erp_cust_az12).

Transformation Logic:
    - Customer ID normalization:
        * Removes the 'NAS' prefix from customer IDs when present
          to ensure consistent key values.

    - Birth date validation:
        * Replaces birth dates greater than the current system date
          with NULL to avoid invalid future dates.

    - Gender standardization:
        * Normalizes gender values to 'Female' and 'Male'.
        * Handles inconsistent formatting, hidden characters
          (non-breaking spaces, tabs, carriage returns), and casing.
        * Defaults to 'n/a' for NULL, empty, or unrecognized values.

Source Table:
    bronze.erp_cust_az12

Target Table:
    silver.erp_cust_az12
====================================================
*/

PRINT '>> Truncating Table: silver.erp_cust_az12';
TRUNCATE TABLE silver.erp_cust_az12;

PRINT '>> Inserting Data into silver.erp_cust_az12';
INSERT INTO silver.erp_cust_az12 (
    cid,
    bdate,
    gen
)

SELECT 
    -- Normalize customer ID by removing NAS prefix
    CASE 
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
        ELSE cid
    END AS cid,

    -- Validate birth date (no future dates)
    CASE 
        WHEN bdate > GETDATE() THEN NULL
        ELSE bdate
    END AS bdate,

    -- Standardize gender values
    CASE 
        WHEN gen IS NULL THEN 'n/a'

        WHEN UPPER(
            TRIM(
                REPLACE(
                    REPLACE(
                        REPLACE(gen, CHAR(160), ''), -- non-breaking space
                    CHAR(9), ''),                  -- tab
                CHAR(13), '')                     -- carriage return
            )
        ) IN ('F', 'FEMALE') THEN 'Female'

        WHEN UPPER(
            TRIM(
                REPLACE(
                    REPLACE(
                        REPLACE(gen, CHAR(160), ''),
                    CHAR(9), ''),
                CHAR(13), '')
            )
        ) IN ('M', 'MALE') THEN 'Male'

        ELSE 'n/a'
    END AS gen

FROM bronze.erp_cust_az12;
