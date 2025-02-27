
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_ship_mode_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_ship_mode_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_net_profit
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_ship_mode_sk
),
SalesAnalysis AS (
    SELECT 
        r.ws_ship_mode_sk,
        r.total_quantity,
        r.total_net_profit,
        COALESCE(i.i_current_price * r.total_quantity, 0) AS estimated_revenue,
        CASE 
            WHEN r.total_net_profit IS NULL OR r.total_quantity = 0 THEN 'No Sales'
            WHEN r.total_net_profit / NULLIF(r.total_quantity, 0) > (SELECT AVG(total_net_profit) FROM RankedSales) THEN 'Above Average'
            ELSE 'Below Average'
        END AS profit_status
    FROM 
        RankedSales r
    LEFT JOIN 
        item i ON i.i_item_sk = (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_ship_mode_sk = r.ws_ship_mode_sk LIMIT 1)
    WHERE 
        r.rank_net_profit <= 3
)
SELECT 
    sm.sm_ship_mode_id, 
    sa.total_quantity,
    sa.total_net_profit,
    sa.estimated_revenue,
    sa.profit_status
FROM 
    SalesAnalysis sa
JOIN 
    ship_mode sm ON sa.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE 
    (sa.profit_status = 'Above Average' OR sa.total_net_profit IS NOT NULL)
ORDER BY 
    sa.total_net_profit DESC
LIMIT 10;
