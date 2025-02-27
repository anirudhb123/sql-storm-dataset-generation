
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM web_sales
    GROUP BY ws_item_sk
), 
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        rs.total_quantity,
        rs.total_profit
    FROM RankedSales rs
    JOIN item i ON rs.ws_item_sk = i.i_item_sk
    WHERE rs.rank_profit <= 10
), 
SalesDetails AS (
    SELECT 
        ti.i_item_id,
        ti.i_item_desc,
        ti.total_quantity,
        ti.total_profit,
        COALESCE(sm.sm_type, 'Unknown') AS ship_mode,
        COALESCE(c.c_state, 'Unknown') AS customer_state,
        COUNT(DISTINCT ws.ws_order_number) AS number_of_orders
    FROM TopItems ti
    LEFT JOIN web_sales ws ON ti.ws_item_sk = ws.ws_item_sk
    LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY ti.i_item_id, ti.i_item_desc, ti.total_quantity, ti.total_profit, sm.sm_type, c.c_state
)
SELECT 
    s.i_item_id,
    s.i_item_desc,
    s.total_quantity,
    s.total_profit,
    s.ship_mode,
    s.customer_state,
    CASE 
        WHEN s.total_profit > 1000 THEN 'High Profit'
        WHEN s.total_profit BETWEEN 500 AND 1000 THEN 'Moderate Profit'
        ELSE 'Low Profit'
    END AS profit_category,
    CASE 
        WHEN s.total_quantity IS NULL THEN 'No Sales'
        ELSE CAST(s.total_quantity AS VARCHAR(10))
    END AS quantity_str,
    DENSE_RANK() OVER (ORDER BY s.total_profit DESC) AS profit_rank
FROM SalesDetails s 
ORDER BY s.total_profit DESC;
