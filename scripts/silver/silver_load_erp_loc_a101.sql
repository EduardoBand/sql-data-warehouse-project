/*
===========================================================
Silver Layer – Customer Location Standardization
===========================================================

This script loads and standardizes customer location data
from the Bronze layer (bronze.erp_loc_a101) into the Silver
layer (silver.erp_loc_a101), applying data cleansing and
normalization rules to improve data quality and consistency.

Transformations applied:

- Customer ID normalization:
  Removes hyphens from the `cid` field to create a
  standardized business key.

- Country field cleansing:
  - Removes hidden and non-printable characters:
    * Non-breaking spaces (CHAR(160))
    * Tab characters (CHAR(9))
    * Carriage returns (CHAR(13))
  - Trims leading and trailing whitespace.
  - Normalizes casing for consistent comparison.

- Country standardization logic:
  - Maps known country codes to full country names:
    * DE   -> Germany
    * US   -> United States
    * USA  -> United States
  - Replaces empty or NULL values with 'n/a'.
  - Formats remaining values using Title Case.
===========================================================
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
