
WITH RECURSIVE income_bands AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_income_band_sk = 1
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib
    JOIN income_bands ibs ON ibs.ib_income_band_sk + 1 = ib.ib_income_band_sk
),
customer_data AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           COUNT(DISTINCT sr.sr_ticket_number) AS returns_count,
           AVG(sr.sr_return_amt) AS avg_return_amt,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY COUNT(DISTINCT sr.sr_ticket_number) DESC) AS rn
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
top_customers AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender
    FROM customer_data c
    JOIN customer_demographics cd ON c.c_customer_sk = cd.cd_demo_sk
    WHERE c.returns_count > (SELECT AVG(returns_count) FROM customer_data)
)
SELECT w.w_warehouse_id,
       w.w_warehouse_name,
       SUM(ws.ws_net_profit) AS total_profit,
       STRING_AGG(DISTINCT CONCAT(COALESCE(c.c_first_name, 'Unknown'), ' ', COALESCE(c.c_last_name, 'Customer'))) AS customers
FROM web_sales ws
JOIN store s ON ws.ws_store_sk = s.s_store_sk
JOIN warehouse w ON s.s_warehouse_sk = w.w_warehouse_sk
LEFT JOIN store_returns sr ON ws.ws_item_sk = sr.sr_item_sk
LEFT JOIN top_customers c ON sr.sr_customer_sk = c.c_customer_sk
WHERE w.w_country = 'USA'
AND ws.ws_sold_date_sk BETWEEN (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
GROUP BY w.w_warehouse_id, w.w_warehouse_name
HAVING total_profit > 1000
ORDER BY total_profit DESC
LIMIT 10;
