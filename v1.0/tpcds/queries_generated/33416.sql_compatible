
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_birth_country,
        1 AS depth
    FROM 
        customer
    WHERE 
        c_birth_country IS NOT NULL

    UNION ALL

    SELECT 
        s.ss_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_country,
        sh.depth + 1
    FROM 
        store_sales s
    JOIN 
        customer c ON s.ss_customer_sk = c.c_customer_sk
    JOIN 
        sales_hierarchy sh ON sh.c_customer_sk = s.ss_customer_sk
    WHERE 
        sh.depth < 5
),
ranked_sales AS (
    SELECT 
        ss_item_sk,
        SUM(ss_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_item_sk
),
address_info AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM 
        customer_address
),
customer_count AS (
    SELECT 
        COUNT(DISTINCT c_customer_sk) AS unique_customers,
        ca_state
    FROM 
        customer c
    LEFT JOIN 
        address_info ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca_state
)
SELECT 
    sh.c_first_name,
    sh.c_last_name,
    sh.c_birth_country,
    COUNT(cs.cs_order_number) AS orders_count,
    COALESCE(cc.unique_customers, 0) AS unique_customers_in_state,
    ra.total_sales,
    ra.sales_rank
FROM 
    sales_hierarchy sh
LEFT JOIN 
    catalog_sales cs ON sh.c_customer_sk = cs.cs_bill_customer_sk
LEFT JOIN 
    ranked_sales ra ON cs.cs_item_sk = ra.ss_item_sk
LEFT JOIN 
    customer_count cc ON cc.ca_state = sh.c_birth_country
WHERE 
    sh.depth = 1
GROUP BY 
    sh.c_first_name, sh.c_last_name, sh.c_birth_country, cc.unique_customers, ra.total_sales, ra.sales_rank
HAVING 
    COUNT(cs.cs_order_number) > 1
ORDER BY 
    ra.total_sales DESC;
