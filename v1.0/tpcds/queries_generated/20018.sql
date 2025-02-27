
WITH RECURSIVE income_bands AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound 
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL
    UNION ALL
    SELECT ib.ib_income_band_sk, 
           CASE WHEN ib.ib_lower_bound IS NULL THEN ib.ib_upper_bound - 500 ELSE ib.ib_lower_bound - 500 END,
           CASE WHEN ib.ib_upper_bound IS NULL THEN ib.ib_lower_bound + 500 ELSE ib.ib_upper_bound + 500 END
    FROM income_bands ib
    WHERE ib.ib_lower_bound > 0
), customer_info AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           cd.cd_marital_status,
           CASE WHEN hd.hd_income_band_sk IS NULL THEN 'Unknown Band' 
                ELSE (SELECT CONCAT(ib.ib_lower_bound, ' to ', ib.ib_upper_bound) 
                      FROM income_band ib 
                      WHERE ib.ib_income_band_sk = hd.hd_income_band_sk) END AS income_band_range
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
), sales_data AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_quantity) AS total_quantity_sold,
           SUM(ws.ws_net_profit) AS total_net_profit,
           ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_sales
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
), top_sales AS (
    SELECT * 
    FROM sales_data 
    WHERE total_quantity_sold > 500 AND total_net_profit IS NOT NULL
)
SELECT ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.cd_marital_status,
       ib.ib_lower_bound,
       ib.ib_upper_bound,
       COALESCE(ts.total_quantity_sold, 0) AS total_sales,
       COALESCE(ts.total_net_profit, 0.00) AS net_profit
FROM customer_info ci
LEFT JOIN top_sales ts ON ci.c_customer_sk = ts.ws_item_sk
FULL OUTER JOIN income_bands ib ON ci.c_current_cdemo_sk = ib.ib_income_band_sk
WHERE (ci.cd_gender = 'M' OR ci.cd_marital_status = 'M')
AND (ib.ib_lower_bound IS NOT NULL OR ib.ib_upper_bound IS NOT NULL)
AND coalesce(ts.total_net_profit, 0) > 0
ORDER BY ci.c_last_name, ci.c_first_name, ib.ib_lower_bound;
