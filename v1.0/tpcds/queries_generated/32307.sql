
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
        0 AS level
    FROM 
        customer c
    WHERE 
        c.c_preferred_cust_flag = 'Y'
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
        sh.level + 1
    FROM 
        customer c
    JOIN 
        sales_hierarchy sh ON c.c_current_cdemo_sk = sh.c_customer_sk
)
, item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales_price,
        SUM(ws.ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    sh.customer_full_name,
    ish.ws_item_sk,
    is.total_sales_price,
    is.total_quantity,
    is.sales_rank,
    CASE 
        WHEN is.total_sales_price IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sale_status
FROM 
    sales_hierarchy sh
LEFT JOIN 
    item_sales is ON sh.c_customer_sk = is.ws_item_sk
WHERE 
    sh.level <= 2
ORDER BY 
    sh.customer_full_name,
    is.sales_rank NULLS LAST;
