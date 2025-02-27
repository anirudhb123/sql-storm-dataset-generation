
WITH RECURSIVE SalesHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status, 
           SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE cd.cd_marital_status = 'M'
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status

    UNION ALL

    SELECT sh.c_customer_sk, sh.c_first_name, sh.c_last_name, 
           sh.cd_gender, sh.cd_marital_status, 
           SUM(ws.ws_net_profit) AS total_profit
    FROM SalesHierarchy sh
    JOIN web_sales ws ON sh.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY sh.c_customer_sk, sh.c_first_name, sh.c_last_name, sh.cd_gender, sh.cd_marital_status
),
TimeRankedSales AS (
    SELECT ws.ws_order_number, ws.ws_sales_price, ws.ws_net_profit,
           DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS ranked_price
    FROM web_sales ws
    WHERE ws.ws_net_profit IS NOT NULL
),
ProfitAnalysis AS (
    SELECT sh.c_first_name, sh.c_last_name, sh.cd_gender, 
           sh.total_profit, tr.ranked_price
    FROM SalesHierarchy sh
    JOIN TimeRankedSales tr ON sh.c_customer_sk = tr.ws_order_number
    WHERE sh.total_profit > (SELECT AVG(total_profit) FROM SalesHierarchy)
)
SELECT p.c_first_name, p.c_last_name, p.cd_gender, 
       COALESCE(NULLIF(p.ranked_price, 0), 'Not Available') AS price_rank
FROM ProfitAnalysis p
WHERE p.total_profit IS NOT NULL
ORDER BY p.total_profit DESC
LIMIT 50;
