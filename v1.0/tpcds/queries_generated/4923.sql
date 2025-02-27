
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1000000 AND 1001000
),
TopProfitableItems AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        RankedSales
    WHERE 
        rn <= 10
    GROUP BY 
        ws_item_sk
),
SalesSummary AS (
    SELECT 
        i.i_item_id,
        t.total_net_profit,
        COALESCE(sm.sm_type, 'No Shipping Method') AS shipping_method,
        COUNT(DISTINCT w.web_site_sk) AS num_websites
    FROM 
        TopProfitableItems t
    JOIN 
        item i ON t.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY 
        i.i_item_id, t.total_net_profit, sm.sm_type
)
SELECT 
    s.i_item_id,
    s.total_net_profit,
    s.shipping_method,
    CONCAT('Total Revenue: $', ROUND(SUM(ws.ws_net_paid), 2)) AS total_revenue,
    CASE 
        WHEN s.total_net_profit IS NULL THEN 'No Profit'
        ELSE CASE 
            WHEN s.total_net_profit > 1000 THEN 'High Profit'
            WHEN s.total_net_profit BETWEEN 500 AND 1000 THEN 'Moderate Profit'
            ELSE 'Low Profit'
        END
    END AS profit_status
FROM 
    SalesSummary s
JOIN 
    web_sales ws ON s.i_item_id = ws.ws_item_sk
WHERE 
    ws.ws_net_profit IS NOT NULL
GROUP BY 
    s.i_item_id, s.total_net_profit, s.shipping_method
HAVING 
    SUM(ws.ws_net_paid) > (SELECT AVG(ws_net_paid) FROM web_sales)
ORDER BY 
    s.total_net_profit DESC;
