/*
====================================================
View: gold.dim_products
====================================================

View Purpose:
    This view creates the Product Dimension in the
    Gold layer of the Data Warehouse.

    It exposes the current (active) product records
    only, providing a clean and analytics-ready
    dimension aligned with star schema modeling
    best practices.

Key Features:
    - Surrogate key generation:
        * Uses ROW_NUMBER() to create a technical
          product_key for analytical joins.

    - Current-state filtering:
        * Filters out historical product versions
          by selecting only records with NULL end
          dates (active SCD Type 2 records).

    - Product identity and attributes:
        * Includes business identifiers, descriptive
          attributes, and product lifecycle metadata.

    - Category enrichment:
        * Joins ERP product category data to enrich
          products with category, subcategory, and
          maintenance attributes.

    - Referential resilience:
        * LEFT JOIN ensures product records are
          retained even if category data is missing.

Source Tables:
    silver.crm_prd_info
    silver.erp_px_cat_g1v2

Usage Example:
    SELECT * FROM gold.dim_products;

Notes:
    - This dimension represents the latest valid
      version of each product.
    - Historical product versions remain available
      in the Silver layer for audit and tracking.

====================================================
*/

CREATE VIEW gold.dim_products AS

SELECT 
ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
pn.prd_id AS product_id,
pn.prd_key AS product_number,
pn.prd_nm AS product_name,
pn.cat_id AS category_id,
pc.cat AS category,
pc.subcat AS subcategory,
pc.maintenance,
pn.prd_cost AS cost,
pn.prd_line AS product_line,
pn.prd_start_dt AS start_date
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
ON pn.cat_id = pc.id
WHERE prd_end_dt is NULL -- Filter out all historical data
