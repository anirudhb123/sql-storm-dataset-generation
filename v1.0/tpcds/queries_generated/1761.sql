
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) as rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451546
),
TopItemSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_quantity) AS total_quantity,
        SUM(rs.ws_net_profit) AS total_net_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.rn <= 10
    GROUP BY 
        rs.ws_item_sk
),
StoreInfo AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_country
    FROM 
        store s
    WHERE 
        s.s_state IN ('CA', 'NY')
),
ProfitableStores AS (
    SELECT 
        si.s_store_sk,
        si.s_store_name,
        COUNT(ts.ws_item_sk) AS product_count,
        SUM(ts.total_net_profit) AS total_net_profit
    FROM 
        StoreInfo si
    LEFT JOIN 
        TopItemSales ts ON si.s_store_sk = ts.ws_item_sk
    GROUP BY 
        si.s_store_sk, si.s_store_name
)
SELECT 
    ps.s_store_name,
    ps.product_count,
    ps.total_net_profit,
    COALESCE((SELECT COUNT(*) FROM store_returns sr WHERE sr.s_store_sk = ps.s_store_sk), 0) AS return_count
FROM 
    ProfitableStores ps
WHERE 
    ps.total_net_profit > 5000
ORDER BY 
    ps.total_net_profit DESC
LIMIT 5;
