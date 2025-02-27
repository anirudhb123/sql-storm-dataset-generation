
WITH RECURSIVE income_brackets AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound 
    FROM income_band 
    WHERE ib_lower_bound IS NOT NULL AND ib_upper_bound IS NULL
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound 
    FROM income_band ib
    JOIN income_brackets ibr ON ibr.ib_income_band_sk + 1 = ib.ib_income_band_sk
),
customer_info AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_customer_sk) AS rn,
           ib.ib_lower_bound,
           ib.ib_upper_bound
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN income_brackets ib ON ib.ib_lower_bound <= hd.hd_income_band_sk AND ib.ib_upper_bound >= hd.hd_income_band_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL AND
          (cd.cd_marital_status = 'S' OR cd.cd_marital_status IS NULL)
),
sales_summary AS (
    SELECT ss.ss_item_sk,
           SUM(ss.ss_quantity) AS total_quantity,
           SUM(ss.ss_net_paid) AS total_net_paid
    FROM store_sales ss 
    GROUP BY ss.ss_item_sk
),
returns_summary AS (
    SELECT sr_item_sk,
           SUM(sr_return_quantity) AS total_returned,
           SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM store_returns 
    GROUP BY sr_item_sk
)
SELECT ci.c_first_name,
       ci.c_last_name,
       ci.cd_gender,
       COALESCE(ss.total_quantity, 0) AS total_sales_quantity,
       COALESCE(ss.total_net_paid, 0) AS total_sales_amount,
       COALESCE(rs.total_returned, 0) AS total_returns_quantity,
       COALESCE(rs.total_returned_amount, 0) AS total_returns_amount
FROM customer_info ci
LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.ss_item_sk
LEFT JOIN returns_summary rs ON ss.ss_item_sk = rs.sr_item_sk
WHERE (total_sales_quantity > 10 OR total_sales_amount > 500) AND
      (ci.ib_lower_bound IS NOT NULL OR ci.ib_upper_bound IS NOT NULL)
ORDER BY ci.cd_gender, ci.rn DESC
LIMIT 100;
