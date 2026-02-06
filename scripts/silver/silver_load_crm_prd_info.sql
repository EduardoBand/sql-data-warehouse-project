/*
==========================================================
 Script Name : Load Silver Layer – Product Dimension
 Layer       : Bronze ➜ Silver
 Table       : silver.crm_prd_info
 Purpose     :
     - Clean and standardize product data coming from the Bronze layer
     - Derive category and product keys from the raw product key
     - Normalize low-cardinality fields (product line)
     - Handle NULL values for numeric columns
     - Implement SCD Type 2 logic by calculating product end dates
     - Prepare data for analytical consumption in the Silver layer

 Key Transformations :
     - Extract category ID from product key
     - Normalize product line values (M, R, S, T → full names)
     - Replace NULL product cost with 0
     - Convert start dates to DATE
     - Calculate end dates using LEAD window function

 Notes :
     - End date is derived as (next start date - 1 day)
     - Latest records will have NULL end dates (can be treated as active)
==========================================================
*/

PRINT '>> Truncating Table: silver.crm_prd_info';
TRUNCATE TABLE silver.crm_prd_info;

PRINT '>> Inserting Data into silver.crm_prd_info';
INSERT INTO silver.crm_prd_info (
    prd_id,
    cat_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
)
SELECT
    -- Product surrogate key
    prd_id,

    -- Category ID derived from the first part of the product key
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,

    -- Business product key (removes category prefix)
    SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,

    -- Product name
    prd_nm,

    -- Replace NULL costs with zero
    ISNULL(prd_cost, 0) AS prd_cost,

    -- Normalize product line codes to descriptive values
    CASE 
        WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
        WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
        WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
        WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
        ELSE 'n/a'
    END AS prd_line,

    -- Product validity start date
    CAST(prd_start_dt AS DATE) AS prd_start_dt,

    -- Product validity end date (SCD Type 2 logic)
    CAST(
        DATEADD(
            DAY,
            -1,
            LEAD(prd_start_dt) OVER (
                PARTITION BY prd_key
                ORDER BY prd_start_dt
            )
        ) AS DATE
    ) AS prd_end_dt

FROM bronze.crm_prd_info;
