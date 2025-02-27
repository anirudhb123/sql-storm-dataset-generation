
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        sd.ss_sold_date_sk,
        CASE 
            WHEN ws.ws_sales_price > 100 THEN 'High'
            WHEN ws.ws_sales_price BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'Low'
        END AS price_category,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS item_rank
    FROM web_sales ws
    LEFT JOIN store_sales sd ON ws.ws_item_sk = sd.ss_item_sk
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    sd.price_category,
    SUM(sd.ws_sales_price) AS total_sales,
    COUNT(DISTINCT sd.ws_order_number) AS order_count,
    MAX(sd.ss_sold_date_sk) AS last_order_date,
    MIN(sd.ss_sold_date_sk) AS first_order_date
FROM customer_hierarchy ch
LEFT JOIN sales_data sd ON ch.c_current_cdemo_sk = sd.ws_item_sk
WHERE sd.price_category IS NOT NULL
GROUP BY ch.c_first_name, ch.c_last_name, sd.price_category
HAVING total_sales > 500
ORDER BY total_sales DESC
LIMIT 10;
