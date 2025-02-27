
WITH RECURSIVE Purchases AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.order_number) AS order_count
    FROM customer AS c
    JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.sold_date_sk >= (
        SELECT MAX(d.d_date_sk)
        FROM date_dim AS d
        WHERE d.d_year = 2023 AND d.d_month_seq IN (1, 2, 3)
    )
    GROUP BY c.c_customer_id
), SeasonalSales AS (
    SELECT
        d.d_year,
        SUM(ws.ws_net_profit) AS seasonal_profit
    FROM date_dim AS d
    JOIN web_sales AS ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE d.d_year IN (2021, 2022) AND d.d_month_seq BETWEEN 1 AND 3
    GROUP BY d.d_year
), ProfitAnalysis AS (
    SELECT 
        p.c_customer_id,
        COALESCE(p.total_net_profit, 0) AS total_net_profit,
        COALESCE(s.seasonal_profit, 0) AS seasonal_profit,
        (COALESCE(p.total_net_profit, 0) - COALESCE(s.seasonal_profit, 0)) AS profit_difference
    FROM Purchases AS p
    FULL OUTER JOIN SeasonalSales AS s ON p.c_customer_id = (SELECT c.c_customer_id FROM customer AS c WHERE c.c_current_cdemo_sk IS NOT NULL LIMIT 1)
)
SELECT
    p.c_customer_id,
    p.total_net_profit,
    p.seasonal_profit,
    CASE 
        WHEN p.profit_difference IS NULL THEN 'No Data'
        WHEN p.profit_difference > 0 THEN 'Profitable'
        ELSE 'Unprofitable'
    END AS profitability_status,
    ROW_NUMBER() OVER (PARTITION BY p.c_customer_id ORDER BY p.total_net_profit DESC) AS rank
FROM ProfitAnalysis AS p
WHERE p.total_net_profit IS NOT NULL
    OR p.seasonal_profit IS NOT NULL
ORDER BY p.total_net_profit DESC
LIMIT 50;

-- Optional Debugging Output
SELECT 
    p.c_customer_id,
    (SELECT COUNT(DISTINCT ws.order_number) 
     FROM web_sales AS ws 
     WHERE ws.ws_bill_customer_sk = p.c_customer_id) AS total_orders,
    AVG(ws.ws_sales_price) AS avg_sales_price
FROM web_sales AS ws
JOIN ProfitAnalysis AS p ON p.c_customer_id = ws.ws_bill_customer_sk
GROUP BY p.c_customer_id
HAVING COUNT(ws.ws_order_number) > 0;
