
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_paid > 100 AND 
        ws.ws_net_profit IS NOT NULL
),
ItemSales AS (
    SELECT 
        i.i_item_id,
        SUM(COALESCE(ws.ws_quantity, 0)) AS total_web_sales,
        SUM(COALESCE(cs.cs_quantity, 0)) AS total_catalog_sales,
        SUM(COALESCE(ss.ss_quantity, 0)) AS total_store_sales,
        CASE 
            WHEN SUM(COALESCE(ws.ws_quantity, 0)) > 500 THEN 'High Seller'
            WHEN SUM(COALESCE(ws.ws_quantity, 0)) BETWEEN 100 AND 500 THEN 'Moderate Seller'
            ELSE 'Low Seller'
        END AS sales_category
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN 
        store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY 
        i.i_item_id
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(COALESCE(sr_return_qty, 0)) AS total_return_qty
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)

SELECT 
    is.i_item_id,
    ir.return_count,
    ir.total_return_qty,
    ISNULL(rs.rank_profit, 0) AS highest_rank_profit,
    is.total_web_sales,
    is.total_catalog_sales,
    is.total_store_sales,
    is.sales_category
FROM 
    ItemSales is
LEFT JOIN 
    CustomerReturns ir ON is.i_item_sk = ir.sr_item_sk
LEFT JOIN 
    RankedSales rs ON is.i_item_sk = rs.ws_item_sk AND rs.rank_profit = 1
WHERE 
    ISNULL(ir.return_count, 0) < 5 AND 
    (is.total_catalog_sales > 100 OR is.total_web_sales > 100)
ORDER BY 
    is.sales_category, 
    highest_rank_profit DESC;
