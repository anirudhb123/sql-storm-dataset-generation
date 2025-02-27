
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_ship_date_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TopItems AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_quantity) AS total_quantity,
        SUM(rs.ws_net_profit) AS total_profit
    FROM RankedSales rs
    WHERE rs.profit_rank <= 5
    GROUP BY rs.ws_item_sk
),
ShipModeStats AS (
    SELECT 
        sm.sm_ship_mode_id,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_ship_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY sm.sm_ship_mode_id
),
FinalReport AS (
    SELECT 
        ti.ws_item_sk,
        ti.total_quantity,
        ti.total_profit,
        s.sm_ship_mode_id,
        s.order_count,
        s.avg_profit
    FROM TopItems ti
    LEFT JOIN ShipModeStats s ON ti.ws_item_sk = s.sm_ship_mode_id
)
SELECT 
    f.ws_item_sk,
    f.total_quantity,
    f.total_profit,
    COALESCE(f.order_count, 0) AS order_count,
    COALESCE(f.avg_profit, 0) AS avg_profit,
    CASE 
        WHEN f.total_profit > 10000 THEN 'High Profit'
        WHEN f.total_profit BETWEEN 5000 AND 10000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM FinalReport f
ORDER BY f.total_profit DESC
LIMIT 100;
