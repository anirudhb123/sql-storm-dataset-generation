
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_paid,
        1 AS level
    FROM web_sales
    WHERE ws_sold_date_sk > 20200101

    UNION ALL

    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity + c.ws_quantity,
        ws_sales_price,
        ws_net_paid + c.ws_net_paid,
        level + 1
    FROM web_sales w
    JOIN sales_cte c ON w.ws_item_sk = c.ws_item_sk
    WHERE w.ws_sold_date_sk = c.ws_sold_date_sk + interval '1 day'
)

SELECT 
    ca.city,
    ca.country,
    c.c_customer_id,
    SUM(ss_quantity) AS total_quantity,
    COUNT(DISTINCT ws_order_number) AS total_orders,
    AVG(ws_sales_price) AS average_sales_price,
    MAX(ws_net_paid) AS max_net_paid,
    CASE 
        WHEN COUNT(DISTINCT ws_order_number) = 0 THEN 'No Sales'
        ELSE CONCAT(ROUND(AVG(ws_net_paid), 2), ' USD')
    END AS avg_net_paid,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers
FROM web_sales ws
INNER JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    (SELECT ws_item_sk, SUM(ws_quantity) AS total_quantity
     FROM web_sales 
     GROUP BY ws_item_sk 
     HAVING SUM(ws_quantity) > 100) AS item_totals ON ws.ws_item_sk = item_totals.ws_item_sk
LEFT JOIN store s ON ws.ws_store_sk = s.s_store_sk
WHERE 
    (ws_sales_price IS NOT NULL AND ws_net_paid > 0) 
    OR (ws_coupon_amt IS NOT NULL AND ws_coupon_amt > 0)
GROUP BY 
    ca.city, ca.country, c.c_customer_id
HAVING 
    total_quantity > 50
ORDER BY 
    total_orders DESC, avg_net_paid DESC
LIMIT 10;
