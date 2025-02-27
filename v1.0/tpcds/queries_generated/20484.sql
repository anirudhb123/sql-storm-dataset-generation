
WITH ranked_sales AS (
    SELECT ws_bill_customer_sk, 
           SUM(ws_net_profit) AS total_profit,
           RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid_inc_ship_tax) DESC) AS profit_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
top_customers AS (
    SELECT c.c_customer_id,
           c.c_first_name,
           c.c_last_name,
           rd.ca_city,
           rd.ca_state,
           rd.ca_country,
           cs.total_profit
    FROM customer c
    JOIN ranked_sales cs ON c.c_customer_sk = cs.ws_bill_customer_sk
    LEFT JOIN customer_address rd ON c.c_current_addr_sk = rd.ca_address_sk
    WHERE cs.profit_rank <= 5
),
customer_demographics AS (
    SELECT cd.cd_demo_sk,
           cd.cd_gender,
           cd.cd_marital_status,
           ib.ib_lower_bound,
           ib.ib_upper_bound,
           COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, ib.ib_lower_bound, ib.ib_upper_bound
),
sales_summary AS (
    SELECT SUM(ws_ext_sales_price) AS total_sales,
           ws_ship_mode_sk,
           COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_ship_mode_sk
)
SELECT tc.c_customer_id,
       tc.c_first_name,
       tc.c_last_name,
       tc.ca_city,
       tc.ca_state,
       tc.ca_country,
       cd.cd_gender,
       cd.cd_marital_status,
       cs.total_sales,
       cs.order_count,
       CASE 
           WHEN cd.customer_count IS NULL THEN 'N/A' 
           ELSE CONCAT('Income Band: ', cd.ib_lower_bound, ' - ', cd.ib_upper_bound) 
       END AS income_band_info
FROM top_customers tc
LEFT JOIN customer_demographics cd ON tc.c_customer_id = cd.cd_demo_sk
LEFT JOIN sales_summary cs ON cs.ws_ship_mode_sk = (
    SELECT sm_ship_mode_sk 
    FROM ship_mode 
    WHERE sm_code = (CASE WHEN tc.ca_state = 'CA' THEN 'CA_Ship' ELSE 'Other_Ship' END)
)
WHERE tc.ca_city IS NOT NULL 
  AND (cd.cd_marital_status IS NOT NULL OR cd.cd_gender IS NULL)
ORDER BY tc.total_profit DESC, cd.cd_marital_status DESC, tc.c_last_name ASC;
