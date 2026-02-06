/*
====================================================
ETL Script: Transform Customer Location Data – ERP (Bronze → Silver)
====================================================

Script Purpose:
    Cleans and standardizes ERP customer location data from the Bronze
    layer (bronze.erp_loc_a101) before loading it into the Silver layer
    (silver.erp_loc_a101).

Transformation Logic:
    - Customer ID normalization:
        * Removes hyphens from customer IDs to ensure a consistent
          and standardized business key.

    - Country field cleansing:
        * Removes hidden and non-printable characters such as:
            - Non-breaking spaces (CHAR(160))
            - Tab characters (CHAR(9))
            - Carriage returns (CHAR(13))
        * Trims leading and trailing whitespace.
        * Normalizes casing for reliable comparisons.

    - Country standardization:
        * Maps known country codes to full country names:
            - DE   → Germany
            - US   → United States
            - USA  → United States
        * Replaces NULL or empty values with 'n/a'.
        * Formats remaining values using Title Case for consistency.

Source Table:
    bronze.erp_loc_a101

Target Table:
    silver.erp_loc_a101
====================================================
*/

INSERT INTO silver.erp_loc_a101 (cid, cntry)

SELECT 
    -- Remove hyphens from customer ID to standardize the key
    REPLACE(cid, '-', '') AS cid,

    -- Standardized country name
    CASE 
        -- Map country codes to full country names
        WHEN cntry_clean = 'DE' THEN 'Germany'
        WHEN cntry_clean IN ('US', 'USA') THEN 'United States'

        -- Handle empty or NULL country values
        WHEN cntry_clean = '' OR cntry_clean IS NULL THEN 'n/a'

        -- Default: format country name using Title Case
        ELSE 
            UPPER(LEFT(cntry_clean, 1)) 
            + LOWER(SUBSTRING(cntry_clean, 2, LEN(cntry_clean)))
    END AS cntry
    -- Hidden whitespace and junk characters required explicit cleaning

FROM bronze.erp_loc_a101

-- Normalize country values before applying business logic
CROSS APPLY (
    SELECT 
        UPPER(                                     -- Normalize casing
            LTRIM(RTRIM(                          -- Remove leading/trailing spaces
                REPLACE(                          -- Remove non-breaking spaces
                    REPLACE(                      -- Remove tab characters
                        REPLACE(cntry, CHAR(160), ''),
                    CHAR(9), ''),
                CHAR(13), '')                     -- Remove carriage returns
            ))
        ) AS cntry_clean
) c;
