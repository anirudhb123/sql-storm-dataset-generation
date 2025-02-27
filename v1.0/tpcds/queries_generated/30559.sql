
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_ship_date_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_ship_date_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM web_sales
    GROUP BY ws_ship_date_sk
),
TopSales AS (
    SELECT 
        d.d_date AS sales_date,
        total_quantity,
        total_profit
    FROM SalesCTE s
    JOIN date_dim d ON s.ws_ship_date_sk = d.d_date_sk
    WHERE rn <= 10
),
AggregatedSales AS (
    SELECT 
        sales_date,
        MAX(total_quantity) AS max_quantity,
        AVG(total_profit) AS avg_profit
    FROM TopSales
    GROUP BY sales_date
)
SELECT 
    COALESCE(a.sales_date, b.sales_date) AS sales_date,
    a.max_quantity,
    b.avg_profit
FROM AggregatedSales a
FULL OUTER JOIN (
    SELECT 
        d.d_date AS sales_date,
        MAX(ws_net_paid_inc_tax) AS max_inc_tax
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY d.d_date
) b ON a.sales_date = b.sales_date
WHERE (a.max_quantity IS NOT NULL OR b.max_inc_tax IS NOT NULL)
ORDER BY sales_date;
