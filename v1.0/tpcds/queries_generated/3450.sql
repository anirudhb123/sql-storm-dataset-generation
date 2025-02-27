
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM 
        store_returns
),
ItemSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
ItemStats AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(rs.total_quantity_sold, 0) AS total_quantity_sold,
        COALESCE(rs.total_profit, 0) AS total_profit,
        CASE 
            WHEN COALESCE(rs.total_quantity_sold, 0) = 0 THEN NULL
            ELSE (COALESCE(rs.total_profit, 0) / COALESCE(rs.total_quantity_sold, 1))
        END AS avg_profit_per_item
    FROM 
        item i
    LEFT JOIN 
        ItemSales rs ON i.i_item_sk = rs.ws_item_sk
),
ReturnStats AS (
    SELECT 
        ir.i_item_desc,
        COUNT(r.rn) AS total_returns,
        SUM(r.sr_return_quantity) AS total_returned_quantity,
        AVG(r.sr_return_quantity) AS avg_return_quantity
    FROM 
        RankedReturns r
    JOIN 
        ItemStats ir ON r.sr_item_sk = ir.i_item_sk
    WHERE 
        r.rn <= 5
    GROUP BY 
        ir.i_item_desc
)
SELECT 
    is.i_item_desc,
    is.total_quantity_sold,
    is.total_profit,
    is.avg_profit_per_item,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(rs.avg_return_quantity, 0) AS avg_return_quantity
FROM 
    ItemStats is
LEFT JOIN 
    ReturnStats rs ON is.i_item_desc = rs.i_item_desc
ORDER BY 
    is.avg_profit_per_item DESC,
    rs.total_returns DESC
FETCH FIRST 10 ROWS ONLY;
