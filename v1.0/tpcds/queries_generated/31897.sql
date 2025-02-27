
WITH RECURSIVE sales_hierarchy AS (
    SELECT s_store_sk, s_store_name, s_manager, s_closed_date_sk, 
           1 AS level
    FROM store
    WHERE s_closed_date_sk IS NULL
    UNION ALL
    SELECT s.s_store_sk, s.s_store_name, s.s_manager, s.s_closed_date_sk, 
           sh.level + 1
    FROM store s
    JOIN sales_hierarchy sh ON s.s_manager = sh.s_store_name
),
agg_sales AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_sales_price) AS total_sales,
           COUNT(ws.ws_order_number) AS order_count,
           DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) as sales_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2022
    GROUP BY ws.ws_item_sk
),
customer_info AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_purchase_estimate,
           HTHD.hd_income_band_sk,
           CASE 
               WHEN HTHD.hd_buy_potential = 'High' THEN 'Premium'
               WHEN HTHD.hd_buy_potential = 'Medium' THEN 'Standard'
               ELSE 'Basic'
           END AS customer_tier
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics HTHD ON HTHD.hd_demo_sk = c.c_current_hdemo_sk
),
total_returns AS (
    SELECT sr_item_sk,
           SUM(sr_return_quantity) AS total_return_qty,
           SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM store_returns
    GROUP BY sr_item_sk
),
final_results AS (
    SELECT ci.c_first_name, 
           ci.c_last_name, 
           ci.cd_gender, 
           ci.customer_tier, 
           as.total_sales,
           COALESCE(tr.total_return_qty, 0) AS total_return_qty,
           COALESCE(tr.total_return_amt, 0) AS total_return_amt,
           sh.s_store_name
    FROM customer_info ci
    JOIN agg_sales as ON as.ws_item_sk = ci.c_customer_sk
    LEFT JOIN total_returns tr ON tr.sr_item_sk = as.ws_item_sk
    JOIN sales_hierarchy sh ON sh.s_store_sk = ci.c_customer_sk
)
SELECT *,
       CASE 
           WHEN total_sales > 1000 THEN 'Top Seller'
           ELSE 'Regular Seller'
       END AS sales_category
FROM final_results
WHERE customer_tier <> 'Basic'
ORDER BY total_sales DESC, customer_tier ASC;
