
WITH RECURSIVE SalesCTE AS (
    SELECT ws_sold_date_sk, 
           ws_item_sk, 
           ws_quantity, 
           ws_sales_price, 
           ws_net_profit, 
           1 AS Level
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(d_date_sk) 
                              FROM date_dim 
                              WHERE d_year = 2022)
    
    UNION ALL
    
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           (ws.ws_quantity + cte.ws_quantity) AS ws_quantity,
           (ws.ws_sales_price + cte.ws_sales_price) AS ws_sales_price,
           (ws.ws_net_profit + cte.ws_net_profit) AS ws_net_profit,
           Level + 1
    FROM web_sales AS ws
    JOIN SalesCTE AS cte ON ws.ws_item_sk = cte.ws_item_sk
    WHERE Level < 3
),
AggregatedSales AS (
    SELECT ws_item_sk,
           SUM(ws_quantity) AS total_quantity,
           SUM(ws_net_profit) AS total_net_profit
    FROM SalesCTE
    GROUP BY ws_item_sk
),
CustomerStats AS (
    SELECT c.c_customer_sk,
           c.c_birth_year,
           cd.cd_gender,
           COUNT(DISTINCT cd.cd_demo_sk) AS total_demographics
    FROM customer AS c
    LEFT JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk, c.c_birth_year, cd.cd_gender
)
SELECT cs.c_customer_sk,
       cs.c_birth_year,
       cs.cd_gender,
       COALESCE(as.total_quantity, 0) AS total_quantity,
       COALESCE(as.total_net_profit, 0) AS total_net_profit
FROM CustomerStats AS cs
LEFT JOIN AggregatedSales AS as ON cs.c_customer_sk = as.ws_item_sk
WHERE cs.c_birth_year IS NOT NULL
ORDER BY total_net_profit DESC, total_quantity DESC
LIMIT 100;
