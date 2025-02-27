
WITH RECURSIVE sales_data AS (
    SELECT ws_item_sk, 
           SUM(ws_quantity) AS total_quantity, 
           SUM(ws_net_profit) AS total_profit,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING SUM(ws_quantity) > 0
), 
customer_info AS (
    SELECT c_customer_sk, 
           c_first_name, 
           c_last_name, 
           cd_marital_status, 
           cd_income_band_sk,
           (SELECT COUNT(*) 
            FROM store_sales s
            WHERE s.ss_customer_sk = c.c_customer_sk) AS store_sales_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M' OR cd.cd_income_band_sk IS NOT NULL
)
SELECT ci.c_first_name, 
       ci.c_last_name, 
       sd.total_quantity, 
       sd.total_profit, 
       (SELECT COUNT(*)
        FROM web_returns wr 
        WHERE wr.wr_returning_customer_sk = ci.c_customer_sk) AS return_count,
       CASE 
          WHEN sd.total_profit IS NULL THEN 'No Sales'
          WHEN sd.total_profit > 1000 THEN 'High Profit'
          WHEN sd.total_profit BETWEEN 500 AND 1000 THEN 'Moderate Profit'
          ELSE 'Low Profit'
       END AS profit_category
FROM customer_info ci
JOIN sales_data sd ON ci.c_customer_sk = sd.ws_item_sk
WHERE ci.store_sales_count > 5
ORDER BY sd.total_profit DESC
LIMIT 20;
