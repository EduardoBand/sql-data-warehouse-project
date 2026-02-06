/*
====================================================
View: gold.fact_sales
====================================================

View Purpose:
    This view creates the Sales Fact table in the
    Gold layer of the Data Warehouse.

    It captures transactional sales measures and
    links them to conformed Product and Customer
    dimensions, enabling analytical queries and
    reporting in a star schema design.

Key Features:
    - Fact grain:
        * One record per sales order line, identified
          by the order number and related dimensions.

    - Dimension integration:
        * Resolves surrogate keys for Product and
          Customer dimensions using Gold views.
        * Enables efficient joins for analytics.

    - Time attributes:
        * Exposes order, shipping, and due dates
          for time-based analysis.

    - Measures:
        * Sales amount, quantity, and price are
          provided as additive facts for reporting.

    - Referential resilience:
        * LEFT JOINs ensure sales records are retained
          even when dimension records are missing.

Source Tables:
    silver.crm_sales_details

Joined Dimensions:
    gold.dim_products
    gold.dim_customers

Usage Example:
    SELECT * FROM gold.fact_sales;

Notes:
    - This fact view assumes dimensions are already
      populated and represent the current business
      state.
    - Designed for analytical and BI workloads.

====================================================
*/

CREATE VIEW gold.fact_sales AS
SELECT
sd.sls_ord_num AS order_number,
pr.product_key,
cu.customer_key,
sd.sls_order_dt AS order_date,
sd.sls_ship_dt AS shipping_date,
sd.sls_due_dt AS due_rate,
sd.sls_sales AS sales_amount,
sd.sls_quantity AS quantity,
sd.sls_price AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
ON sd.sls_cust_id = cu.customer_id

