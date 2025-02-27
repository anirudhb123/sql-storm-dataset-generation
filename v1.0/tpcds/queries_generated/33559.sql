
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_marital_status,
           cd.cd_gender,
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_customer_sk) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status IS NOT NULL

    UNION ALL

    SELECT ch.c_customer_sk,
           CONCAT(ch.c_first_name, ' (Descendant of ', ch.c_customer_sk, ')') AS c_first_name,
           ch.c_last_name,
           cd.cd_marital_status,
           cd.cd_gender,
           ROW_NUMBER() OVER (PARTITION BY ch.c_customer_sk ORDER BY ch.c_customer_sk) AS rn
    FROM CustomerHierarchy ch
    JOIN customer c ON c.c_customer_sk = ch.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender IS NOT NULL
), 

SalesData AS (
    SELECT ws.ws_sold_date_sk,
           SUM(ws.ws_net_profit) AS total_net_profit,
           SUM(ws.ws_quantity) AS total_quantity,
           ROW_NUMBER() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS sale_rank
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk
),

TopSales AS (
    SELECT sd.ws_sold_date_sk, 
           sd.total_net_profit,
           sd.total_quantity
    FROM SalesData sd
    WHERE sd.sale_rank <= 10
),

CombinedSales AS (
    SELECT th.c_customer_sk,
           th.c_first_name,
           th.c_last_name,
           th.cd_marital_status,
           th.cd_gender,
           COALESCE(ts.total_net_profit, 0) AS net_profit,
           COALESCE(ts.total_quantity, 0) AS quantity
    FROM CustomerHierarchy th
    LEFT JOIN TopSales ts ON th.rn = ts.ws_sold_date_sk
)

SELECT *,
       CASE 
           WHEN net_profit = 0 THEN 'No Sales'
           ELSE 'Sales Made'
       END AS sales_status
FROM CombinedSales
WHERE sales_status = 'No Sales'
ORDER BY c_gender, net_profit DESC;
