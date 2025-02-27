
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM web_sales ws
),
SalesData AS (
    SELECT 
        r.web_site_sk,
        r.ws_order_number,
        COALESCE(r.ws_net_profit, 0) AS net_profit,
        CASE 
            WHEN r.ws_net_profit IS NULL THEN 'No Profit'
            WHEN r.ws_net_profit < 0 THEN 'Loss'
            ELSE 'Profit'
        END AS profit_status,
        SUM(CASE WHEN r.profit_rank = 1 THEN r.ws_net_profit ELSE 0 END) OVER (PARTITION BY r.web_site_sk) AS total_top_profit
    FROM RankedSales r
),
CustomerProfit AS (
    SELECT 
        c.c_customer_id,
        SUM(sd.net_profit) AS total_customer_profit,
        COUNT(sd.ws_order_number) AS order_count
    FROM customer c
    JOIN SalesData sd ON c.c_customer_sk = sd.web_site_sk
    GROUP BY c.c_customer_id
    HAVING SUM(sd.net_profit) IS NOT NULL
)
SELECT 
    cp.c_customer_id,
    cp.total_customer_profit,
    CASE 
        WHEN cp.order_count > 5 THEN 'Frequent Shopper'
        WHEN cp.order_count BETWEEN 1 AND 5 THEN 'Occasional Shopper'
        ELSE 'New Customer'
    END AS customer_type,
    NULLIF(cp.total_customer_profit, 0) AS adjusted_profit,
    CASE 
        WHEN cp.total_customer_profit > 1000 THEN 'VIP'
        WHEN cp.total_customer_profit IS NULL THEN 'No Profit'
        ELSE 'Standard Customer'
    END AS profitability_segment
FROM CustomerProfit cp
WHERE 
    cp.total_customer_profit IS NOT NULL
    AND cp.total_customer_profit < (SELECT AVG(total_customer_profit) FROM CustomerProfit)
ORDER BY cp.total_customer_profit DESC
LIMIT 10
UNION ALL
SELECT 
    '-1' AS c_customer_id,
    SUM(ws.ws_net_profit) AS total_net_profit,
    0 AS order_count,
    'Aggregate' AS customer_type,
    NULLIF(SUM(ws.ws_net_profit), 0) AS adjusted_profit,
    CASE 
        WHEN SUM(ws.ws_net_profit) > 500000 THEN 'Top Earner'
        ELSE 'Below Average'
    END AS profitability_segment
FROM web_sales ws
WHERE 
    ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
    AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023);
