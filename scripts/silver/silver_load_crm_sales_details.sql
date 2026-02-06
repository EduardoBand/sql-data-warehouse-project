/*
Purpose:
Cleans and standardizes sales data from the Bronze layer before loading into Silver.

Logic applied:
- Converts integer-based dates (YYYYMMDD) into DATE format
- Replaces invalid dates (0 or incorrect length) with NULL
- Recalculates sales amount when missing, invalid, or inconsistent
- Fixes price values when missing or non-positive
*/

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
