
WITH RECURSIVE sales_data AS (
    SELECT ws_sold_date_sk, ws_item_sk, ws_quantity, ws_net_paid, ws_net_profit,
           1 AS level
    FROM web_sales
    WHERE ws_sales_price > 100.00
    UNION ALL
    SELECT ws.ws_sold_date_sk, ws.ws_item_sk, ws.ws_quantity, ws.ws_net_paid, ws.ws_net_profit,
           sd.level + 1
    FROM web_sales ws
    INNER JOIN sales_data sd ON ws.ws_item_sk = sd.ws_item_sk
    WHERE sd.level < 3
),
top_items AS (
    SELECT ws_item_sk, SUM(ws_net_profit) AS total_net_profit,
           ROW_NUMBER() OVER (ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM sales_data
    GROUP BY ws_item_sk
),
customer_info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           COALESCE(cd.cd_gender, 'U') AS gender,
           COUNT(ws.ws_order_number) AS total_orders,
           SUM(ws.ws_net_profit) AS total_spent
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
)
SELECT ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.gender, 
       COALESCE(ti.total_net_profit, 0) AS top_item_profit,
       ci.total_orders, ci.total_spent,
       CASE 
           WHEN ci.total_spent > 1000 THEN 'Premium'
           WHEN ci.total_spent BETWEEN 500 AND 1000 THEN 'Standard'
           ELSE 'Basic'
       END AS customer_status
FROM customer_info ci
LEFT JOIN top_items ti ON ti.ws_item_sk = (SELECT ws_item_sk FROM top_items LIMIT 1)
WHERE ci.total_orders > 0
ORDER BY ci.total_spent DESC
LIMIT 10;
