
WITH RECURSIVE sales_hierarchy AS (
    SELECT s_store_sk, ss_sold_date_sk, ss_item_sk, 
           SUM(ss_net_profit) AS total_profit,
           COUNT(ss_ticket_number) AS total_sales
    FROM store_sales 
    GROUP BY s_store_sk, ss_sold_date_sk, ss_item_sk
),
rich_customers AS (
    SELECT DISTINCT c_customer_sk, c_first_name, c_last_name,
           cd.education_status, cd.gender,
           COUNT(DISTINCT ss_ticket_number) AS purchases
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c_customer_sk, c_first_name, c_last_name, cd.education_status, cd.gender 
    HAVING COUNT(DISTINCT ss_ticket_number) > 5
),
fluctuating_ship_modes AS (
    SELECT sm.sm_ship_mode_id, AVG(ws.ws_net_profit) AS avg_profit
    FROM ship_mode sm
    JOIN web_sales ws ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    GROUP BY sm.sm_ship_mode_id
    HAVING AVG(ws.ws_net_profit) > (
        SELECT AVG(ws1.ws_net_profit)
        FROM web_sales ws1
        GROUP BY ws1.ws_ship_mode_sk
        ORDER BY AVG(ws1.ws_net_profit) DESC
        LIMIT 1 OFFSET 1
    )
),
final_sales AS (
    SELECT sh.s_store_sk, sh.ss_item_sk, 
           sh.total_profit, sh.total_sales,
           COALESCE(RANK() OVER (PARTITION BY sh.s_store_sk ORDER BY sh.total_profit DESC), 0) AS profit_rank,
           COALESCE((SELECT LOW_INCOME_THRESHOLD FROM income_band WHERE ib_lower_bound < sh.total_sales LIMIT 1), 'Unknown') AS income_band
    FROM sales_hierarchy sh
    LEFT JOIN rich_customers rc ON rc.purchases > (SELECT AVG(purchases) FROM rich_customers)
)
SELECT fs.s_store_sk, fs.ss_item_sk,
       SUM(fs.total_profit) AS grand_total_profit, 
       AVG(fs.total_sales) AS average_sales,
       CASE WHEN fs.income_band IS NOT NULL THEN fs.income_band ELSE 'No data' END AS financial_band,
       STRING_AGG(DISTINCT rc.c_first_name || ' ' || rc.c_last_name, ', ') AS high_value_customers
FROM final_sales fs
LEFT JOIN rich_customers rc ON fs.s_store_sk = rc.c_customer_sk
GROUP BY fs.s_store_sk, fs.ss_item_sk, fs.income_band
HAVING SUM(fs.total_profit) > (
    SELECT AVG(total_profit) FROM final_sales
)
ORDER BY grand_total_profit DESC 
LIMIT 10 OFFSET 5;
