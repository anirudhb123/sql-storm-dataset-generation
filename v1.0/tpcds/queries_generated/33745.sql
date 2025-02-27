
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales,
        1 AS level
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    
    UNION ALL
    
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) + sh.total_sales AS total_sales,
        sh.level + 1
    FROM 
        customer ch
    JOIN 
        sales_hierarchy sh ON ch.c_current_cdemo_sk = sh.c_customer_sk
    LEFT JOIN 
        web_sales ws ON ch.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ch.c_customer_sk, ch.c_first_name, ch.c_last_name, sh.total_sales, sh.level
)

SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    sh.total_sales,
    CASE 
        WHEN sh.total_sales > 1000 THEN 'High Value'
        WHEN sh.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    d.d_year,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    AVG(ws.ws_sales_price) OVER(PARTITION BY c.c_customer_sk) AS avg_order_value,
    STRING_AGG(DISTINCT CONCAT(i.i_item_id, ': ', i.i_item_desc), ', ') AS purchased_items
FROM 
    customer c
LEFT JOIN 
    sales_hierarchy sh ON c.c_customer_sk = sh.c_customer_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year >= 2020
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name, sh.total_sales, d.d_year
ORDER BY 
    total_sales DESC
LIMIT 100;
