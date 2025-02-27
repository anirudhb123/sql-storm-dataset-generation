
WITH RECURSIVE income_bracket AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band 
    WHERE ib_income_band_sk = 1
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib
    JOIN income_bracket ib_w ON ib.ib_income_band_sk = ib_w.ib_income_band_sk + 1
),
sales_data AS (
    SELECT ws.web_site_sk, ws.ws_order_number, ws.ws_quantity, 
           ws.ws_ext_sales_price, ws.ws_net_profit,
           COALESCE(i.i_current_price, 0) AS current_price,
           COALESCE(NULLIF((ws.ws_ext_sales_price - ws.ws_coupon_amt), 0), NULL) AS adjusted_price
    FROM web_sales ws
    LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
customer_stats AS (
    SELECT cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate,
           COUNT(DISTINCT c.c_customer_sk) AS total_customers,
           AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
),
returns_summary AS (
    SELECT sr_item_sk, SUM(sr_return_quantity) AS total_returns,
           SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM store_returns
    GROUP BY sr_item_sk
),
final_summary AS (
    SELECT sd.web_site_sk, cs.cd_gender, cs.cd_marital_status,
           SUM(sd.ws_quantity) AS total_sold,
           SUM(sd.ws_net_profit) AS total_profit,
           COALESCE(rs.total_returns, 0) AS total_returns,
           COALESCE(rs.total_returned_amount, 0) AS total_returned_amount
    FROM sales_data sd
    JOIN customer_stats cs ON cs.total_customers > 0
    LEFT JOIN returns_summary rs ON sd.ws_order_number = rs.sr_item_sk
    GROUP BY sd.web_site_sk, cs.cd_gender, cs.cd_marital_status
)
SELECT f.web_site_sk, f.cd_gender, f.cd_marital_status, 
       f.total_sold, f.total_profit,
       CASE 
           WHEN f.total_sold > 100 THEN 'High Seller'
           WHEN f.total_sold BETWEEN 50 AND 100 THEN 'Medium Seller'
           ELSE 'Low Seller'
       END AS seller_category,
       ib.ib_lower_bound, ib.ib_upper_bound
FROM final_summary f
JOIN income_bracket ib ON f.total_profit BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
ORDER BY f.web_site_sk, f.cd_gender, f.cd_marital_status;
