
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, 
           hd.hd_income_band_sk, hd.hd_buy_potential, 
           ROW_NUMBER() OVER (PARTITION BY hd.hd_income_band_sk ORDER BY c.c_customer_id) AS rn
    FROM customer c
    JOIN household_demographics hd ON c.c_current_cdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_buy_potential IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, 
           hd.hd_income_band_sk, hd.hd_buy_potential, 
           ROW_NUMBER() OVER (PARTITION BY hd.hd_income_band_sk ORDER BY c.c_customer_id) AS rn
    FROM customer c
    JOIN household_demographics hd ON c.c_current_cdemo_sk = hd.hd_demo_sk
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
    WHERE hd.hd_buy_potential IS NOT NULL AND ch.rn < 10
),
sales_summary AS (
    SELECT ws_bill_customer_sk, SUM(ws_ext_sales_price) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS order_count,
           AVG(ws_net_profit) AS avg_net_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
returns_summary AS (
    SELECT wr_returning_customer_sk, SUM(wr_return_amt) AS total_returns,
           COUNT(DISTINCT wr_order_number) AS return_count
    FROM web_returns
    GROUP BY wr_returning_customer_sk
)
SELECT ch.c_first_name, ch.c_last_name,
       COALESCE(ss.total_sales, 0) AS total_sales,
       COALESCE(rs.total_returns, 0) AS total_returns,
       (COALESCE(ss.total_sales, 0) - COALESCE(rs.total_returns, 0)) AS net_sales,
       CASE
           WHEN COALESCE(ss.order_count, 0) > 0 THEN 
               ROUND((COALESCE(ss.total_sales, 0) - COALESCE(rs.total_returns, 0)) 
               / COALESCE(ss.order_count, 1), 2)
           ELSE 0
       END AS avg_sale_per_order,
       DENSE_RANK() OVER (ORDER BY (COALESCE(ss.total_sales, 0) - COALESCE(rs.total_returns, 0)) DESC) AS sale_rank
FROM customer_hierarchy ch
LEFT JOIN sales_summary ss ON ch.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN returns_summary rs ON ch.c_customer_sk = rs.wr_returning_customer_sk
WHERE ch.hd_income_band_sk IS NOT NULL
ORDER BY net_sales DESC
LIMIT 100;
