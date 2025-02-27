
WITH RECURSIVE StoreHierarchy AS (
    SELECT s_store_sk, s_store_id, s_store_name, s_manager, s_division_id, 1 AS level
    FROM store
    WHERE s_manager IS NOT NULL
    UNION ALL
    SELECT s.s_store_sk, s.s_store_id, s.s_store_name, s.s_manager, s.s_division_id, sh.level + 1
    FROM store s
    JOIN StoreHierarchy sh ON s.s_division_id = sh.s_division_id
    WHERE sh.level < 5
),
CustomerStats AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status,
           SUM(COALESCE(ss.ss_net_paid, 0)) AS total_spent,
           COUNT(ss.ss_ticket_number) AS total_purchases
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
HighSpenders AS (
    SELECT c.c_customer_sk, c.total_spent, c.total_purchases,
           DENSE_RANK() OVER (ORDER BY c.total_spent DESC) AS rank
    FROM CustomerStats c
    WHERE c.total_spent > (SELECT AVG(total_spent) FROM CustomerStats)
),
SalesByStore AS (
    SELECT s.s_store_sk, s.s_store_name, SUM(ws.ws_net_profit) AS total_profit
    FROM store s
    JOIN web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
    GROUP BY s.s_store_sk, s.s_store_name
),
StorePerformance AS (
    SELECT s.s_store_name, sh.level, sb.total_profit,
           COUNT(DISTINCT h.c_customer_sk) AS distinct_high_spenders
    FROM StoreHierarchy sh
    JOIN SalesByStore sb ON sh.s_store_sk = sb.s_store_sk
    LEFT JOIN HighSpenders h ON h.total_spent > 1000
    GROUP BY s.s_store_name, sh.level, sb.total_profit
)
SELECT * 
FROM StorePerformance
WHERE total_profit > 10000 
ORDER BY distinct_high_spenders DESC, total_profit DESC;
