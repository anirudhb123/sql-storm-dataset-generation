
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ws_sold_date_sk,
        ws_sales_price,
        ws_ext_sales_price,
        ws_quantity,
        ws_item_sk,
        1 AS level
    FROM web_sales
    WHERE ws_sold_date_sk > (SELECT MAX(d_date_sk) - 365 FROM date_dim)
    UNION ALL
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        ws.ws_item_sk,
        sh.level + 1
    FROM web_sales ws
    JOIN sales_hierarchy sh ON ws.ws_sold_date_sk = sh.ws_sold_date_sk
    WHERE ws.ws_sales_price > (SELECT AVG(ws_sales_price) FROM web_sales)
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    SUM(sh.ws_ext_sales_price) AS total_sales,
    AVG(sh.ws_sales_price) AS avg_sales_per_product,
    SUM(COALESCE(sh.ws_quantity, 0)) AS total_quantity
FROM customer_address ca
LEFT OUTER JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN sales_hierarchy sh ON c.c_customer_sk = sh.ws_item_sk 
WHERE ca.ca_state IN ('CA', 'NY')
GROUP BY ca.ca_city, ca.ca_state
HAVING SUM(sh.ws_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 10;
