/*
====================================================
ETL Script: Load Silver Layer - crm_cust_info
====================================================

Script Purpose:
    This script loads data from the Bronze layer 
    (bronze.crm_cust_info) into the Silver layer 
    (silver.crm_cust_info) with the following logic:

    - Deduplicates records: only the latest record 
      per customer (cst_id) is kept using ROW_NUMBER().
    - Cleans textual data: trims spaces from first and 
      last names.
    - Standardizes categorical values:
        * Marital Status: 'S' → 'Single', 'M' → 'Married', others → 'Unknown/Other'
        * Gender: 'F' → 'Female', 'M' → 'Male', others → 'Unknown/Other'
    - Filters out invalid or empty rows:
        * Removes rows with NULL cst_id
        * Removes rows with empty or NULL first/last names

Target Table:
    silver.crm_cust_info

Source Table:
    bronze.crm_cust_info

====================================================
*/


INSERT INTO silver.crm_cust_info (
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    cst_create_date
)
SELECT 
    cst_id,
    cst_key,
    TRIM(cst_firstname) AS cst_firstname,
    TRIM(cst_lastname) AS cst_lastname,
    CASE 
        WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
        WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
        ELSE 'Unknown/Other'
    END AS cst_marital_status,
    CASE 
        WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
        WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
        ELSE 'Unknown/Other'
    END AS cst_gndr,
    cst_create_date
FROM (
    SELECT *, 
           ROW_NUMBER() OVER (
               PARTITION BY cst_id 
               ORDER BY cst_create_date DESC
           ) AS flag_last
    FROM bronze.crm_cust_info
    WHERE cst_id IS NOT NULL           -- Remove NULL IDs before row_number
      AND TRIM(ISNULL(cst_firstname, '')) <> '' -- Remove empty first names
      AND TRIM(ISNULL(cst_lastname, '')) <> ''  -- Remove empty last names
) t
WHERE flag_last = 1;
