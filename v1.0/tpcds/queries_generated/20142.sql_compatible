
WITH ranked_sales AS (
    SELECT 
        cs_bill_customer_sk,
        cs_item_sk,
        cs_order_number,
        cs_sales_price,
        ROW_NUMBER() OVER (PARTITION BY cs_bill_customer_sk ORDER BY cs_sales_price DESC) AS rank
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
customer_info AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_marital_status,
        cd_gender,
        cd_purchase_estimate,
        c_current_addr_sk
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
address_info AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
    WHERE 
        ca_state = 'CA'
),
filtered_sales AS (
    SELECT 
        rs.cs_bill_customer_sk,
        rs.cs_item_sk,
        rs.cs_order_number,
        rs.cs_sales_price,
        ci.c_first_name,
        ci.c_last_name,
        ai.ca_city,
        ai.ca_zip,
        CASE 
            WHEN ci.cd_marital_status IS NULL THEN 'Unknown'
            ELSE ci.cd_marital_status 
        END AS marital_status,
        CASE 
            WHEN ci.cd_gender = 'M' THEN 'Male'
            WHEN ci.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender_description
    FROM 
        ranked_sales rs
    JOIN 
        customer_info ci ON rs.cs_bill_customer_sk = ci.c_customer_sk
    LEFT JOIN 
        address_info ai ON ci.c_current_addr_sk = ai.ca_address_sk
    WHERE 
        rs.rank <= 10
)
SELECT 
    fs.cs_bill_customer_sk,
    COUNT(fs.cs_item_sk) AS total_items_count,
    SUM(fs.cs_sales_price) AS total_sales_value,
    AVG(fs.cs_sales_price) AS average_sales_price,
    MAX(fs.cs_sales_price) AS max_sales_price,
    MIN(fs.cs_sales_price) AS min_sales_price,
    STRING_AGG(DISTINCT fs.c_first_name || ' ' || fs.c_last_name) AS customer_names,
    STRING_AGG(DISTINCT fs.ca_city || ', ' || fs.ca_zip) AS unique_addresses,
    CASE 
        WHEN COUNT(fs.cs_item_sk) > 5 THEN 'High Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM 
    filtered_sales fs
GROUP BY 
    fs.cs_bill_customer_sk
HAVING 
    AVG(fs.cs_sales_price) > (SELECT AVG(cs_sales_price) FROM catalog_sales) 
    AND COUNT(fs.cs_item_sk) > 0
ORDER BY 
    total_sales_value DESC
LIMIT 100;
