
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, 
           CASE 
               WHEN ca_city IS NULL THEN 'Unknown City'
               ELSE ca_city 
           END AS city_label,
           0 AS level
    FROM customer_address
    WHERE ca_state IS NOT NULL
    UNION ALL
    SELECT a.ca_address_sk, a.ca_city, a.ca_state,
           'Additional Level: ' || a.ca_city AS city_label,
           ah.level + 1
    FROM customer_address a
    JOIN address_hierarchy ah ON a.ca_state = ah.ca_state
    WHERE ah.level < 3
)
SELECT customer.c_customer_id,
       COALESCE(dc.d_day_name, 'N/A') AS day_name,
       SUM(ws.ws_net_profit) AS total_profit,
       STRING_AGG(DISTINCT ah.city_label, ', ') AS associated_cities,
       COUNT(DISTINCT ws.ws_order_number) AS order_count,
       MAX(ws.ws_sales_price) OVER (PARTITION BY customer.c_customer_sk ORDER BY ws.ws_sales_price DESC ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) AS highest_sales_price,
       (SELECT COUNT(*) FROM store WHERE s_state = 'NY') AS ny_stores,
       COUNT(DISTINCT CASE WHEN cd.cd_gender = 'F' THEN customer.c_customer_id END) AS female_customers
FROM customer
LEFT JOIN web_sales ws ON customer.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN customer_demographics cd ON customer.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN date_dim dc ON ws.ws_sold_date_sk = dc.d_date_sk
LEFT JOIN address_hierarchy ah ON customer.c_current_addr_sk = ah.ca_address_sk
GROUP BY customer.c_customer_id, dc.d_day_name
HAVING SUM(ws.ws_net_profit) > (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2 WHERE ws2.ws_sold_date_sk > 2000)
ORDER BY total_profit DESC
LIMIT 10 OFFSET 5;
