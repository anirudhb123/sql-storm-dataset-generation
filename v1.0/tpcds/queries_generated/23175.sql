
WITH RECURSIVE CustomerRecursion AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name,
           c.c_preferred_cust_flag, d.d_date, 
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY d.d_date DESC) AS rn
    FROM customer c
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
SalesData AS (
    SELECT ws.ws_item_sk, ws.ws_quantity, ws.ws_sales_price,
           ws.ws_net_profit,
           CASE 
               WHEN ws.ws_quantity < 5 THEN 'Low Sales'
               WHEN ws.ws_quantity BETWEEN 5 AND 20 THEN 'Moderate Sales'
               ELSE 'High Sales' 
           END AS sales_category
    FROM web_sales ws
    WHERE ws.ws_sales_price IS NOT NULL
),
HighValueCustomers AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status,
           SUM(ss.ss_net_profit) AS total_net_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
    HAVING SUM(ss.ss_net_profit) > 10000
),
ReturnData AS (
    SELECT wr_returning_customer_sk,
           COUNT(wr_return_number) AS return_count,
           SUM(wr_return_amt) AS total_return
    FROM web_returns wr
    GROUP BY wr_returning_customer_sk
),
FinalOutput AS (
    SELECT cc.c_first_name, cc.c_last_name,
           COALESCE(SUM(sd.ws_net_profit), 0) AS total_sales_profit,
           rc.return_count,
           HVC.total_net_profit,
           RANK() OVER (ORDER BY COALESCE(SUM(sd.ws_net_profit), 0) DESC) AS sales_rank
    FROM CustomerRecursion cc
    LEFT JOIN SalesData sd ON cc.c_customer_sk = sd.ws_item_sk
    LEFT JOIN ReturnData rc ON cc.c_customer_sk = rc.wr_returning_customer_sk
    LEFT JOIN HighValueCustomers HVC ON cc.c_customer_sk = HVC.cd_demo_sk
    WHERE cc.rn = 1
    GROUP BY cc.c_first_name, cc.c_last_name, rc.return_count, HVC.total_net_profit
)

SELECT *, 
       CASE 
           WHEN total_sales_profit IS NULL THEN 'No Sales' 
           ELSE CASE
               WHEN total_sales_profit > 20000 THEN 'Top Customer'
               WHEN total_sales_profit BETWEEN 10000 AND 20000 THEN 'Medium Customer'
               ELSE 'Low Customer'
           END
       END AS customer_rating
FROM FinalOutput
ORDER BY sales_rank, total_sales_profit DESC NULLS LAST;
