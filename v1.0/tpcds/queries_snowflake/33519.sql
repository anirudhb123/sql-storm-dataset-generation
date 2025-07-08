
WITH RECURSIVE sales_cte AS (
    SELECT ws_item_sk, SUM(ws_quantity) AS total_quantity
    FROM web_sales
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2023 AND d_month_seq = 10
    )
    GROUP BY ws_item_sk
    
    UNION ALL
    
    SELECT ws_item_sk, total_quantity + cs_quantity
    FROM sales_cte
    INNER JOIN catalog_sales ON sales_cte.ws_item_sk = catalog_sales.cs_item_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    SUM(w.ws_sales_price) AS total_sales,
    COUNT(DISTINCT w.ws_order_number) AS order_count,
    RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(w.ws_sales_price) DESC) AS sales_rank,
    CASE
        WHEN SUM(w.ws_sales_price) > 1000 THEN 'High Value'
        WHEN SUM(w.ws_sales_price) BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM customer c
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales w ON c.c_customer_sk = w.ws_bill_customer_sk
LEFT JOIN sales_cte sc ON w.ws_item_sk = sc.ws_item_sk
WHERE ca.ca_state = 'CA' 
    AND w.ws_sold_date_sk IS NOT NULL
GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city
HAVING COUNT(w.ws_order_number) > 1
ORDER BY total_sales DESC
LIMIT 10;
