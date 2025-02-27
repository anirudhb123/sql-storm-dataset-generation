
WITH RECURSIVE sales_hierarchy AS (
    SELECT ss_store_sk, 
           SUM(ss_net_profit) AS total_net_profit,
           1 AS level
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2451545 AND 2451575  -- Filtering for a specific date range
    GROUP BY ss_store_sk
    UNION ALL
    SELECT s.s_store_sk, 
           SUM(ss.net_profit) AS total_net_profit,
           sh.level + 1
    FROM store s
    JOIN sales_hierarchy sh ON s.s_store_sk = sh.ss_store_sk
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451545 AND 2451575
    GROUP BY s.s_store_sk, sh.level
),
date_sales AS (
    SELECT d.d_date, 
           SUM(ws.ws_net_profit) AS daily_profit,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk  
    WHERE d.d_year = 2023
    GROUP BY d.d_date
),
comparison AS (
    SELECT d.d_date,
           d.daily_profit,
           COALESCE(lag(d.daily_profit) OVER (ORDER BY d.d_date), 0) AS previous_day_profit,
           d.total_orders,
           (d.daily_profit - COALESCE(lag(d.daily_profit) OVER (ORDER BY d.d_date), 0)) AS profit_change
    FROM date_sales d
)
SELECT d.d_date,
       d.daily_profit,
       d.previous_day_profit,
       d.total_orders,
       CASE 
           WHEN d.profit_change > 0 THEN 'Increase'
           WHEN d.profit_change < 0 THEN 'Decrease'
           ELSE 'No Change'
       END AS profit_trend
FROM comparison d
ORDER BY d.d_date;

SELECT a.ca_country, 
       COUNT(DISTINCT c.c_customer_sk) AS num_customers, 
       SUM(ss.ss_net_profit) AS total_profit
FROM customer_address a
JOIN customer c ON a.ca_address_sk = c.c_current_addr_sk
LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY a.ca_country
HAVING total_profit > 100000
ORDER BY total_profit DESC;

SELECT ib.ib_income_band_sk, 
       ib.ib_lower_bound,
       ib.ib_upper_bound, 
       COUNT(DISTINCT c.c_customer_sk) AS customer_count,
       SUM(ws.ws_net_paid) AS total_spending
FROM income_band ib
LEFT JOIN household_demographics hd ON ib.ib_income_band_sk = hd.hd_income_band_sk
LEFT JOIN customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE ws.ws_sold_date_sk BETWEEN 2451545 AND 2451575
GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY total_spending DESC;
