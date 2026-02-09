# 📒 Data Dictionary – Gold Layer

## Overview

The **Gold layer** represents the business-level data model, optimized for **analytics, reporting, and decision-making**. It contains curated **dimension** and **fact** tables with applied business rules and trusted metrics.

---

## 1. `gold.dim_customers`

**Purpose**  
Stores customer details enriched with demographic and geographic information. Used as a conformed dimension across analytical models.

### Columns

| Column Name       | Data Type        | Description |
|------------------|------------------|-------------|
| customer_key     | INT              | Surrogate key uniquely identifying each customer record in the dimension table |
| customer_id      | INT              | Unique numerical identifier assigned to each customer |
| customer_number  | NVARCHAR(50)     | Alphanumeric identifier representing the customer, used for tracking and referencing |
| first_name       | NVARCHAR(50)     | Customer's first name as recorded in the system |
| last_name        | NVARCHAR(50)     | Customer's last name or family name |
| country          | NVARCHAR(50)     | Country of residence (e.g., 'Australia') |
| marital_status   | NVARCHAR(50)     | Marital status of the customer (e.g., 'Married', 'Single') |
| gender           | NVARCHAR(50)     | Gender of the customer (e.g., 'Male', 'Female', 'N/A') |
| birthdate        | DATE             | Customer date of birth in YYYY-MM-DD format (e.g., 1971-10-06) |
| create_date      | DATE             | Date when the customer record was created in the system |

---

## 2. `gold.dim_products`

**Purpose**  
Stores product master data used to describe and categorize products across fact tables.

### Columns

| Column Name          | Data Type        | Description |
|----------------------|------------------|-------------|
| product_key          | INT              | Surrogate key uniquely identifying each product record in the dimension table |
| product_id           | INT              | Unique identifier assigned to the product for internal tracking and referencing |
| product_number       | NVARCHAR(50)     | Structured alphanumeric code representing the product, used for categorization or inventory |
| product_name         | NVARCHAR(50)     | Descriptive name of the product, including key attributes such as type, color, and size |
| category_id          | NVARCHAR(50)     | Identifier linking the product to its high-level category |
| category             | NVARCHAR(50)     | Broad product classification (e.g., 'Bikes', 'Components') |
| subcategory          | NVARCHAR(50)     | Detailed classification of the product within the category |
| maintenance_required | NVARCHAR(50)     | Indicates whether the product requires maintenance (e.g., 'Yes', 'No') |
| cost                 | INT              | Base cost of the product expressed in whole currency units |
| product_line         | NVARCHAR(50)     | Product line or series to which the product belongs (e.g., 'Road', 'Mountain') |
| start_date           | DATE             | Date when the product became available for sale or use |

---

## 3. `gold.fact_sales`

**Purpose**  
Stores transactional sales data at the grain of **one row per product per customer per date**, used for revenue and performance analysis.

### Columns

| Column Name   | Data Type        | Description |
|--------------|------------------|-------------|
| order_number | NVARCHAR(50)     | Unique alphanumeric identifier for each sales order (e.g., 'SO54496') |
| product_key  | INT              | Surrogate key linking the order to the product dimension |
| customer_key | INT              | Surrogate key linking the order to the customer dimension |
| order_date   | DATE             | Date when the order was placed |
| shipping_date| DATE             | Date when the order was shipped to the customer |
| due_date     | DATE             | Date when payment for the order was due |
| sales_amount | INT              | Total monetary value of the sale for the line item in whole currency units |
| quantity     | INT              | Number of units ordered for the line item |
| price        | INT              | Price per unit for the product in whole currency units |

---

📌 **Notes**

- All Gold tables contain validated and business-approved data  
- Metrics should be sourced exclusively from fact tables  
- Dimensions are shared across analytical models  
