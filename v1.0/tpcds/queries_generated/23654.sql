
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status IS NOT NULL AND 
        cd.cd_purchase_estimate > 1000
    GROUP BY 
        ws.ws_item_sk, ws.web_site_sk
),
HighQuantityItems AS (
    SELECT 
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        CASE 
            WHEN inv.inv_quantity_on_hand IS NULL THEN 'Out of Stock'
            ELSE 'In Stock'
        END AS stock_status
    FROM 
        inventory inv
    WHERE 
        inv.inv_quantity_on_hand IS NOT NULL 
        OR inv.inv_quantity_on_hand = 0
),
RecentReturns AS (
    SELECT 
        cr.cr_item_sk,
        COUNT(*) AS return_count,
        SUM(cr.cr_return_amount) AS total_return
    FROM 
        catalog_returns cr
    JOIN 
        date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
    WHERE 
        dd.d_date > CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    COALESCE(rs.total_quantity, 0) AS sold_quantity,
    COALESCE(rs.total_profit, 0) AS total_profit,
    COALESCE(hqi.inv_quantity_on_hand, 0) AS inventory_quantity,
    COALESCE(hqi.stock_status, 'Stock Not Found') AS inventory_status,
    COALESCE(rr.return_count, 0) AS recent_return_count,
    COALESCE(rr.total_return, 0.00) AS total_returned_amount
FROM 
    item i
LEFT JOIN 
    RankedSales rs ON i.i_item_sk = rs.ws_item_sk AND rs.profit_rank = 1
LEFT JOIN 
    HighQuantityItems hqi ON i.i_item_sk = hqi.inv_item_sk
LEFT JOIN 
    RecentReturns rr ON i.i_item_sk = rr.cr_item_sk
WHERE 
    (i.i_current_price IS NOT NULL AND i.i_current_price > 0)
    OR (SELECT COUNT(*) FROM web_sales w WHERE w.ws_item_sk = i.i_item_sk) > 0
ORDER BY 
    total_profit DESC, sold_quantity DESC;
