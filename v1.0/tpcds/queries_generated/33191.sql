
WITH RECURSIVE date_ranges AS (
    SELECT MIN(d_date_sk) AS start_date_sk, MAX(d_date_sk) AS end_date_sk
    FROM date_dim
),
customer_profiles AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           cd.cd_credit_rating,
           hd.hd_income_band_sk,
           COALESCE(hd.hd_dep_count, 0) AS dep_count,
           COALESCE(hd.hd_vehicle_count, 0) AS vehicle_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
product_sales AS (
    SELECT ws.ws_item_sk, 
           SUM(ws.ws_quantity) AS total_sold,
           SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
sales_rank AS (
    SELECT ps.ws_item_sk,
           ps.total_sold, 
           ps.total_net_profit,
           DENSE_RANK() OVER (ORDER BY ps.total_net_profit DESC) AS rank
    FROM product_sales ps
),
top_products AS (
    SELECT sr.ws_item_sk, sr.total_sold, sr.total_net_profit
    FROM sales_rank sr
    WHERE sr.rank <= 10
),
return_summary AS (
    SELECT trwr.ws_item_sk,
           COALESCE(SUM(trwr.wr_return_quantity), 0) AS total_returns,
           COALESCE(SUM(trwr.wr_return_amt), 0) AS total_return_amount
    FROM web_returns trwr
    GROUP BY trwr.ws_item_sk
)
SELECT cp.c_first_name, 
       cp.c_last_name, 
       tp.total_sold, 
       tp.total_net_profit, 
       rs.total_returns,
       rs.total_return_amount,
       CASE 
           WHEN rs.total_return_amount > 0 THEN 
               ROUND((rs.total_return_amount / tp.total_net_profit) * 100, 2)
           ELSE
               0 
       END AS return_percentage
FROM customer_profiles cp
JOIN top_products tp ON cp.c_customer_sk = tp.total_sold
LEFT JOIN return_summary rs ON tp.ws_item_sk = rs.ws_item_sk
WHERE cp.dep_count > 2
  AND cp.hd_income_band_sk IN (SELECT ib_income_band_sk FROM income_band WHERE ib_lower_bound >= 50000)
ORDER BY return_percentage DESC
LIMIT 100;
