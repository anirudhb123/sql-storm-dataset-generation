
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_qty as quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rn,
        ws.ws_net_profit,
        COALESCE(NULLIF(ws.ws_net_profit / NULLIF(ws.ws_net_paid_inc_ship_tax, 0), 0), 0) AS profit_margin,
        DENSE_RANK() OVER (ORDER BY ws.ws_net_paid_inc_tax DESC) AS tax_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk BETWEEN 20220101 AND 20221231
),

SalesAnalysis AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        SUM(rs.quantity) AS total_quantity,
        AVG(rs.profit_margin) AS avg_profit_margin,
        MAX(rs.tax_rank) AS max_tax_rank
    FROM 
        RankedSales rs
    WHERE 
        rs.rn = 1
    GROUP BY 
        rs.ws_order_number, rs.ws_item_sk
),

HighProfitItems AS (
    SELECT 
        sa.ws_item_sk,
        COUNT(*) AS count_orders
    FROM 
        SalesAnalysis sa
    WHERE 
        sa.avg_profit_margin > (SELECT AVG(profit_margin) FROM RankedSales)
    GROUP BY 
        sa.ws_item_sk
)

SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit,
    COALESCE(SUM(CASE WHEN hpi.count_orders IS NOT NULL THEN 1 ELSE 0 END), 0) AS high_profit_item_count
FROM 
    customer c
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    HighProfitItems hpi ON ws.ws_item_sk = hpi.ws_item_sk
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name
HAVING 
    total_net_profit > 1000
ORDER BY 
    total_net_profit DESC
LIMIT 50;
