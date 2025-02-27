
WITH RECURSIVE sales_trends AS (
    SELECT ws_sold_date_sk, 
           ws_item_sk, 
           SUM(ws_net_paid) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT st.ws_sold_date_sk, 
           st.ws_item_sk,
           st.total_sales + ws.ws_net_paid AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY st.ws_item_sk ORDER BY st.ws_sold_date_sk DESC) AS sales_rank
    FROM sales_trends st
    JOIN web_sales ws ON ws.ws_sold_date_sk = st.ws_sold_date_sk - 1 AND ws.ws_item_sk = st.ws_item_sk
    WHERE st.sales_rank < 5
),
top_items AS (
    SELECT ws_item_sk, 
           SUM(ws_net_paid) AS total_net_profit
    FROM web_sales
    GROUP BY ws_item_sk
    ORDER BY total_net_profit DESC
    LIMIT 10
)
SELECT ci.c_customer_id,
       ci.c_first_name,
       ci.c_last_name,
       ca.ca_city,
       SUM(ws.ws_net_profit) AS total_profit,
       AVG(ws.ws_net_paid_inc_tax) AS avg_paid,
       COUNT(DISTINCT ws.ws_order_number) AS total_orders
FROM web_sales ws
JOIN customer ci ON ci.c_customer_sk = ws.ws_ship_customer_sk
JOIN customer_address ca ON ca.ca_address_sk = ci.c_current_addr_sk
JOIN top_items ti ON ti.ws_item_sk = ws.ws_item_sk
LEFT JOIN (
    SELECT ws_item_sk,
           MAX(ws_sold_date_sk) AS last_sold_date,
           COUNT(*) AS sales_count
    FROM web_sales
    GROUP BY ws_item_sk
) last_sales ON last_sales.ws_item_sk = ws.ws_item_sk
WHERE ws.ws_ship_date_sk IS NOT NULL
GROUP BY ci.c_customer_id, ci.c_first_name, ci.c_last_name, ca.ca_city
HAVING total_profit > 1000
ORDER BY total_profit DESC;
