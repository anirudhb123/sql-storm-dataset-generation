
WITH RECURSIVE sales_data AS (
    SELECT ws_sold_date_sk, ws_item_sk, 
           SUM(ws_quantity) AS total_quantity,
           SUM(ws_net_profit) AS total_profit
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT cs.sold_date_sk, cs.item_sk,
           SUM(cs.quantity) AS total_quantity,
           SUM(cs.net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN sales_data sd ON cs.sold_date_sk = sd.ws_sold_date_sk
    GROUP BY cs.sold_date_sk, cs.item_sk
),
customer_stats AS (
    SELECT c.c_customer_sk,
           d.d_year,
           cd.cd_gender,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders,
           COUNT(DISTINCT sr.ticket_number) AS total_returns,
           SUM(ws.ws_net_profit) AS net_profit,
           CASE WHEN SUM(ws.ws_net_profit) IS NULL THEN 0 ELSE SUM(ws.ws_net_profit) END AS safe_profit
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY c.c_customer_sk, d.d_year, cd.cd_gender
),
final_sales_data AS (
    SELECT a.c_customer_sk,
           a.total_orders,
           a.total_returns,
           a.net_profit,
           a.safe_profit,
           ROW_NUMBER() OVER (PARTITION BY a.cd_gender ORDER BY a.safe_profit DESC) AS profit_rank
    FROM customer_stats a
),
ranked_sales AS (
    SELECT fs.c_customer_sk,
           fs.total_orders,
           fs.total_returns,
           fs.net_profit,
           fs.safe_profit,
           fs.profit_rank,
           COALESCE(TIMESTAMPDIFF(YEAR, CONCAT(d.d_birth_year, '-01-01'), CURDATE()), 0) AS customer_age
    FROM final_sales_data fs
    JOIN customer c ON fs.c_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN (SELECT c_customer_sk, YEAR(CURDATE()) - c_birth_year AS d_birth_year
               FROM customer) d ON c.c_customer_sk = d.c_customer_sk
)
SELECT r.customer_age,
       SUM(r.net_profit) AS total_net_profit,
       COUNT(DISTINCT r.c_customer_sk) AS customer_count,
       AVG(r.safe_profit) AS avg_safe_profit
FROM ranked_sales r
WHERE r.profit_rank <= 10
GROUP BY r.customer_age
ORDER BY customer_age;
