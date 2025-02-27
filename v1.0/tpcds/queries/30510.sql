
WITH RECURSIVE sales_cte AS (
    SELECT ss_item_sk, SUM(ss_net_profit) AS total_profit, 
           ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_net_profit) DESC) AS rn
    FROM store_sales
    GROUP BY ss_item_sk

    UNION ALL

    SELECT ss.ss_item_sk, SUM(ss.ss_net_profit) + cte.total_profit,
           ROW_NUMBER() OVER (PARTITION BY ss.ss_item_sk ORDER BY SUM(ss.ss_net_profit) + cte.total_profit DESC) AS rn
    FROM store_sales ss
    JOIN sales_cte cte ON ss.ss_item_sk = cte.ss_item_sk
    WHERE cte.rn < 5
    GROUP BY ss.ss_item_sk, cte.total_profit
),
address_info AS (
    SELECT c.c_customer_sk, ca.ca_city, 
           COUNT(DISTINCT web_sales.ws_order_number) AS total_orders
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ON c.c_customer_sk = web_sales.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, ca.ca_city
),
item_performance AS (
    SELECT i.i_item_sk, i.i_item_id, MAX(i.i_current_price) AS max_price,
           MIN(i.i_current_price) AS min_price,
           AVG(i.i_current_price) AS avg_price
    FROM item i
    INNER JOIN (
        SELECT ss_item_sk, SUM(ss_sales_price) AS total_sales
        FROM store_sales
        GROUP BY ss_item_sk
    ) ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY i.i_item_sk, i.i_item_id
)
SELECT ai.ca_city, ip.i_item_id, ip.max_price, 
       ip.min_price, ip.avg_price, 
       si.total_profit
FROM address_info ai
CROSS JOIN item_performance ip
JOIN sales_cte si ON ip.i_item_sk = si.ss_item_sk 
WHERE ai.total_orders > 10
  AND (ai.ca_city LIKE '%San%' OR ai.ca_city IS NULL)
ORDER BY ai.ca_city, ip.avg_price DESC
LIMIT 50;
