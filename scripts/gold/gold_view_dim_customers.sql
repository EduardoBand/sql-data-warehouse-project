/*
====================================================
View: gold.dim_customers
====================================================

View Purpose:
    This view creates the Customer Dimension in the
    Gold layer of the Data Warehouse.

    It consolidates and conforms customer-related data
    from multiple Silver-layer sources (CRM and ERP),
    producing a single, analytics-ready dimension
    following star schema best practices.

Key Features:
    - Surrogate key generation:
        * Uses ROW_NUMBER() to create a technical
          customer_key for analytical joins.

    - Customer identity mapping:
        * Exposes both business identifiers
          (customer_id, customer_number).

    - Data enrichment:
        * Combines demographic, geographic, and
          lifecycle attributes into a single view.

    - Gender mastering logic:
        * CRM is treated as the primary source
          for gender when it contains informative values.
        * ERP gender is used as a fallback when CRM
          values are 'Unknown/Other'.
        * Defaults to 'n/a' when neither source
          provides a valid value.

    - Referential integration:
        * LEFT JOINs ensure customer records are
          preserved even when related ERP data
          is missing.

Source Tables:
    silver.crm_cust_info
    silver.erp_cust_az12
    silver.erp_loc_a101

Usage Example:
    SELECT * FROM gold.dim_customers;

====================================================
*/

CREATE VIEW gold.dim_customers AS

SELECT
	ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,-- to generate the SURROGATE KEY
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	la.cntry AS country,
	ci.cst_marital_status AS marital_status,
	CASE WHEN ci.cst_gndr != 'Unknown/Other' THEN ci.cst_gndr -- CR is the master for gender info
		 ELSE COALESCE(ca.gen, 'n/a')
	END AS gender,
	ca.bdate AS birthdate,
	ci.cst_create_date AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON ci.cst_key = la.cid
