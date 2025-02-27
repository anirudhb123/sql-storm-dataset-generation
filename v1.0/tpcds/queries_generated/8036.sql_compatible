
WITH CustomerData AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk, 
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, 
             cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
),
IncomeBands AS (
    SELECT ib.ib_income_band_sk, 
           (SELECT COUNT(*) FROM CustomerData WHERE cd_income_band_sk = ib.ib_income_band_sk) AS customer_count,
           SUM(cd.total_profit) AS total_band_profit
    FROM income_band ib
    LEFT JOIN CustomerData cd ON ib.ib_income_band_sk = cd.cd_income_band_sk
    GROUP BY ib.ib_income_band_sk
)
SELECT ib.ib_income_band_sk, ib.customer_count, ib.total_band_profit,
       CASE 
           WHEN ib.customer_count > 0 THEN ib.total_band_profit / ib.customer_count 
           ELSE 0 
       END AS average_profit_per_customer
FROM IncomeBands ib
ORDER BY ib.ib_income_band_sk;
