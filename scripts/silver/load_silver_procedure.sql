/*
====================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
====================================================

Script Purpose:
    This stored procedure loads and transforms data
    from the Bronze layer into the Silver layer of
    the Data Warehouse.

    It performs the following actions:
    - Truncates Silver tables before loading data.
    - Applies data cleansing and standardization rules.
    - Deduplicates records where required.
    - Implements business logic and data validations.
    - Inserts transformed data into Silver tables
      using INSERT INTO ... SELECT statements.

Parameters:
    None
    This procedure does not accept any parameters or
    return any values.

Usage Example:
    EXEC silver.load_silver;
====================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @start_time DATETIME,
        @end_time DATETIME,
        @batch_start_time DATETIME,
        @batch_end_time DATETIME;

    BEGIN TRY
        SET @batch_start_time = GETDATE();

        PRINT '================================';
        PRINT 'Starting Silver Layer Load';
        PRINT '================================';

        /* ====================================================
           1. ERP – Customer Location
        ==================================================== */
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_loc_a101';
        TRUNCATE TABLE silver.erp_loc_a101;

        PRINT '>> Inserting Data into silver.erp_loc_a101';
        INSERT INTO silver.erp_loc_a101 (cid, cntry)
        SELECT 
            REPLACE(cid, '-', '') AS cid,
            CASE 
                WHEN cntry_clean = 'DE' THEN 'Germany'
                WHEN cntry_clean IN ('US', 'USA') THEN 'United States'
                WHEN cntry_clean = '' OR cntry_clean IS NULL THEN 'n/a'
                ELSE 
                    UPPER(LEFT(cntry_clean, 1)) 
                    + LOWER(SUBSTRING(cntry_clean, 2, LEN(cntry_clean)))
            END
        FROM bronze.erp_loc_a101
        CROSS APPLY (
            SELECT UPPER(
                LTRIM(RTRIM(
                    REPLACE(REPLACE(REPLACE(cntry, CHAR(160), ''), CHAR(9), ''), CHAR(13), '')
                ))
            ) AS cntry_clean
        ) c;

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';
        PRINT '--------------------------------';

        /* ====================================================
           2. ERP – Customer Master
        ==================================================== */
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_cust_az12';
        TRUNCATE TABLE silver.erp_cust_az12;

        PRINT '>> Inserting Data into silver.erp_cust_az12';
        INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
        SELECT 
            CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid)) ELSE cid END,
            CASE WHEN bdate > GETDATE() THEN NULL ELSE bdate END,
            CASE 
                WHEN gen IS NULL THEN 'n/a'
                WHEN UPPER(TRIM(REPLACE(REPLACE(REPLACE(gen, CHAR(160),''),CHAR(9),''),CHAR(13),'')))
                     IN ('F','FEMALE') THEN 'Female'
                WHEN UPPER(TRIM(REPLACE(REPLACE(REPLACE(gen, CHAR(160),''),CHAR(9),''),CHAR(13),'')))
                     IN ('M','MALE') THEN 'Male'
                ELSE 'n/a'
            END
        FROM bronze.erp_cust_az12;

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';
        PRINT '--------------------------------';

        /* ====================================================
           3. ERP – Product Category
        ==================================================== */
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
        TRUNCATE TABLE silver.erp_px_cat_g1v2;

        PRINT '>> Inserting Data into silver.erp_px_cat_g1v2';
        INSERT INTO silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
        SELECT id, cat, subcat, maintenance
        FROM bronze.erp_px_cat_g1v2;

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';
        PRINT '--------------------------------';

        /* ====================================================
           4. CRM – Sales Details
        ==================================================== */
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_sales_details';
        TRUNCATE TABLE silver.crm_sales_details;

        PRINT '>> Inserting Data into silver.crm_sales_details';
        INSERT INTO silver.crm_sales_details (
            sls_ord_num, sls_prd_key, sls_cust_id,
            sls_order_dt, sls_ship_dt, sls_due_dt,
            sls_sales, sls_quantity, sls_price
        )
        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) <> 8 THEN NULL
                 ELSE CAST(CAST(sls_order_dt AS VARCHAR(8)) AS DATE) END,
            CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) <> 8 THEN NULL
                 ELSE CAST(CAST(sls_ship_dt AS VARCHAR(8)) AS DATE) END,
            CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) <> 8 THEN NULL
                 ELSE CAST(CAST(sls_due_dt AS VARCHAR(8)) AS DATE) END,
            CASE 
                WHEN sls_sales IS NULL OR sls_sales <= 0
                  OR sls_sales <> sls_quantity * ABS(sls_price)
                THEN sls_quantity * ABS(sls_price)
                ELSE sls_sales
            END,
            sls_quantity,
            CASE 
                WHEN sls_price IS NULL OR sls_price <= 0
                THEN sls_sales / NULLIF(sls_quantity,0)
                ELSE sls_price
            END
        FROM bronze.crm_sales_details;

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';
        PRINT '--------------------------------';

        /* ====================================================
           5. CRM – Product Dimension (SCD2)
        ==================================================== */
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_prd_info';
        TRUNCATE TABLE silver.crm_prd_info;

        PRINT '>> Inserting Data into silver.crm_prd_info';
        INSERT INTO silver.crm_prd_info (
            prd_id, cat_id, prd_key, prd_nm,
            prd_cost, prd_line, prd_start_dt, prd_end_dt
        )
        SELECT
            prd_id,
            REPLACE(SUBSTRING(prd_key,1,5),'-','_'),
            SUBSTRING(prd_key,7,LEN(prd_key)),
            prd_nm,
            ISNULL(prd_cost,0),
            CASE 
                WHEN UPPER(TRIM(prd_line))='M' THEN 'Mountain'
                WHEN UPPER(TRIM(prd_line))='R' THEN 'Road'
                WHEN UPPER(TRIM(prd_line))='S' THEN 'Other Sales'
                WHEN UPPER(TRIM(prd_line))='T' THEN 'Touring'
                ELSE 'n/a'
            END,
            CAST(prd_start_dt AS DATE),
            CAST(DATEADD(DAY,-1,
                LEAD(prd_start_dt) OVER (
                    PARTITION BY prd_key ORDER BY prd_start_dt
                )
            ) AS DATE)
        FROM bronze.crm_prd_info;

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';
        PRINT '--------------------------------';

        /* ====================================================
           6. CRM – Customer Dimension
        ==================================================== */
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;

        PRINT '>> Inserting Data into silver.crm_cust_info';
        INSERT INTO silver.crm_cust_info (
            cst_id, cst_key, cst_firstname, cst_lastname,
            cst_marital_status, cst_gndr, cst_create_date
        )
        SELECT
            cst_id, cst_key,
            TRIM(cst_firstname), TRIM(cst_lastname),
            CASE 
                WHEN UPPER(TRIM(cst_marital_status))='S' THEN 'Single'
                WHEN UPPER(TRIM(cst_marital_status))='M' THEN 'Married'
                ELSE 'Unknown/Other'
            END,
            CASE 
                WHEN UPPER(TRIM(cst_gndr))='F' THEN 'Female'
                WHEN UPPER(TRIM(cst_gndr))='M' THEN 'Male'
                ELSE 'Unknown/Other'
            END,
            cst_create_date
        FROM (
            SELECT *, ROW_NUMBER() OVER (
                PARTITION BY cst_id ORDER BY cst_create_date DESC
            ) rn
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
              AND TRIM(ISNULL(cst_firstname,'')) <> ''
              AND TRIM(ISNULL(cst_lastname,'')) <> ''
        ) t
        WHERE rn = 1;

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' seconds';
        PRINT '--------------------------------';

        SET @batch_end_time = GETDATE();
        PRINT '================================';
        PRINT 'Silver Layer Load Completed Successfully';
        PRINT 'Total Duration: ' 
            + CAST(DATEDIFF(SECOND,@batch_start_time,@batch_end_time) AS NVARCHAR)
            + ' seconds';
        PRINT '================================';

    END TRY
    BEGIN CATCH
        PRINT '================================';
        PRINT 'ERROR DURING SILVER LOAD';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '================================';
    END CATCH
END;
GO
