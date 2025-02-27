
WITH RECURSIVE CTE_Customer_Income AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_income_band_sk,
           HD.hd_income_band_sk, 
           CASE 
               WHEN HD.hd_income_band_sk IS NULL THEN 'Unknown'
               ELSE (SELECT CONCAT(CAST(ib.ib_lower_bound AS CHAR), '-', CAST(ib.ib_upper_bound AS CHAR)) 
                     FROM income_band ib 
                     WHERE ib.ib_income_band_sk = HD.hd_income_band_sk)
           END AS income_band_range
    FROM customer c
    LEFT JOIN household_demographics HD ON c.c_current_hdemo_sk = HD.hd_demo_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
    UNION ALL
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_income_band_sk,
           HD.hd_income_band_sk,
           CASE 
               WHEN HD.hd_income_band_sk IS NULL THEN 'Unknown'
               ELSE (SELECT CONCAT(CAST(ib.ib_lower_bound AS CHAR), '-', CAST(ib.ib_upper_bound AS CHAR)) 
                     FROM income_band ib 
                     WHERE ib.ib_income_band_sk = HD.hd_income_band_sk)
           END AS income_band_range
    FROM customer c
    INNER JOIN CTE_Customer_Income prev ON prev.c_customer_sk = c.c_customer_sk
    LEFT JOIN household_demographics HD ON c.c_current_hdemo_sk = HD.hd_demo_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
),
Aggregated_Sales AS (
    SELECT ws_bill_cdemo_sk, 
           SUM(ws_net_profit) AS total_profit,
           COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_cdemo_sk
)
SELECT CTE.c_first_name,
       CTE.c_last_name,
       CTE.income_band_range,
       COALESCE(AG.total_profit, 0) AS total_profit,
       COALESCE(AG.total_orders, 0) AS total_orders
FROM CTE_Customer_Income CTE
LEFT JOIN Aggregated_Sales AG ON CTE.cd_demo_sk = AG.ws_bill_cdemo_sk
WHERE (total_profit > 1000 OR total_orders > 10)
ORDER BY total_profit DESC
LIMIT 10;
