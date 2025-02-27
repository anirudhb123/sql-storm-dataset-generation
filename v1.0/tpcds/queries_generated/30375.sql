
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, 
           0 AS level
    FROM customer c
    WHERE c.c_preferred_cust_flag = 'Y'
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, 
           ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_hdemo_sk = ch.c_customer_sk
), 
sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        AVG(ws.ws_net_paid) AS avg_sale_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY ws.ws_item_sk
), 
top_sales AS (
    SELECT 
        ss.ws_item_sk, 
        ss.total_quantity, 
        ss.total_sales, 
        ss.avg_sale_price
    FROM sales_summary ss
    WHERE ss.rank <= 5
)
SELECT 
    ch.c_customer_id,
    ch.c_first_name,
    ch.c_last_name,
    COALESCE(ts.total_quantity, 0) AS total_quantity,
    COALESCE(ts.total_sales, 0.00) AS total_sales,
    CASE 
        WHEN ts.avg_sale_price IS NULL THEN 'No Sales'
        ELSE CONCAT('$', ROUND(ts.avg_sale_price, 2))
    END AS avg_sale_price
FROM customer_hierarchy ch
LEFT JOIN top_sales ts ON ch.c_customer_sk = ts.ws_item_sk;
