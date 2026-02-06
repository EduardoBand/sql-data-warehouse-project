/*
====================================================
ETL Script: Transform Sales Data – Bronze to Silver
====================================================

Script Purpose:
    Cleans and standardizes sales data from the Bronze layer
    (bronze.crm_sales_details) before loading it into the
    Silver layer (silver.crm_sales_details).

Transformation Logic:
    - Date normalization:
        * Converts integer-based dates (YYYYMMDD) to DATE format.
        * Replaces invalid dates (0 or incorrect length) with NULL
          to avoid incorrect timelines.

    - Sales amount validation:
        * Recalculates sales amount when the value is:
            - NULL
            - Non-positive
            - Inconsistent with quantity × price
        * Uses quantity × absolute price as the corrected value.

    - Price correction:
        * Recomputes price when missing or non-positive.
        * Derives price using sales ÷ quantity, preventing
          division by zero with NULLIF().

Source Table:
    bronze.crm_sales_details

Target Table:
    silver.crm_sales_details
====================================================
*/

PRINT '>> Truncating Table: silver.crm_sales_details';
TRUNCATE TABLE silver.crm_sales_details;

PRINT '>> Inserting Data into silver.crm_sales_details';
INSERT INTO silver.crm_sales_details (
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
)

SELECT
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,

    -- Order date: convert valid YYYYMMDD integers to DATE, else NULL
    CASE 
        WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_order_dt AS VARCHAR(8)) AS DATE)
    END AS sls_order_dt,

    -- Ship date: same validation logic
    CASE 
        WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_ship_dt AS VARCHAR(8)) AS DATE)
    END AS sls_ship_dt,

    -- Due date: same validation logic
    CASE 
        WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_due_dt AS VARCHAR(8)) AS DATE)
    END AS sls_due_dt,

    -- Sales amount: recalculate if NULL, non-positive, or inconsistent
    CASE 
        WHEN sls_sales IS NULL 
          OR sls_sales <= 0 
          OR sls_sales != sls_quantity * ABS(sls_price)
        THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales,

    sls_quantity,

    -- Price: derive from sales and quantity if missing or invalid
    CASE 
        WHEN sls_price IS NULL OR sls_price <= 0
        THEN sls_sales / NULLIF(sls_quantity, 0)
        ELSE sls_price
    END AS sls_price

FROM bronze.crm_sales_details;
