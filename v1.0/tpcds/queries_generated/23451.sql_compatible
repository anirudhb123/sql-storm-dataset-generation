
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
StoreReturnStats AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns
    WHERE 
        sr_return_quantity IS NOT NULL AND sr_return_amt > 0
    GROUP BY 
        sr_item_sk
),
TopItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_net_profit,
        srs.return_count,
        srs.total_return_amt,
        srs.avg_return_quantity
    FROM 
        RankedSales rs
    LEFT JOIN 
        StoreReturnStats srs ON rs.ws_item_sk = srs.sr_item_sk
    WHERE 
        rs.profit_rank <= 10
)
SELECT 
    ti.ws_item_sk, 
    ti.total_quantity, 
    COALESCE(ti.total_net_profit, 0) AS total_net_profit, 
    COALESCE(ti.return_count, 0) AS return_count,
    COALESCE(ti.total_return_amt, 0.00) AS total_return_amt,
    COALESCE(ti.avg_return_quantity, 0.00) AS avg_return_quantity,
    CASE 
        WHEN ti.return_count < 5 THEN 'Low Return'
        WHEN ti.return_count BETWEEN 5 AND 10 THEN 'Moderate Return'
        ELSE 'High Return'
    END AS return_category
FROM 
    TopItems ti
WHERE 
    ti.total_net_profit IS NOT NULL OR ti.total_quantity >= 1000
ORDER BY 
    ti.total_net_profit DESC, 
    ti.return_count ASC
LIMIT 50 OFFSET 10
UNION ALL
SELECT 
    inv.inv_item_sk,
    SUM(inv.inv_quantity_on_hand) AS inventory_quantity,
    NULL AS total_net_profit,
    NULL AS return_count,
    NULL AS total_return_amt,
    NULL AS avg_return_quantity,
    'Inventory Item' AS return_category
FROM 
    inventory inv
WHERE 
    inv.inv_quantity_on_hand IS NOT NULL AND inv.inv_quantity_on_hand < 20
GROUP BY 
    inv.inv_item_sk
HAVING 
    SUM(inv.inv_quantity_on_hand) < (
        SELECT 
            AVG(total_quantity) 
        FROM 
            RankedSales
    )
ORDER BY 
    inventory_quantity ASC;
