
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        sr_return_tax,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_return_amt DESC) AS return_rank
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
ItemSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_item_sk
)
SELECT 
    ir.i_item_id,
    ir.i_item_desc,
    COALESCE(SUM(rr.sr_return_quantity), 0) AS total_returned,
    COALESCE(SUM(ir.total_sales_quantity), 0) AS total_sales,
    COALESCE(SUM(ir.total_net_profit), 0) AS total_net_profit,
    (COALESCE(SUM(rr.sr_return_quantity), 0) * 1.0 / NULLIF(COALESCE(SUM(ir.total_sales_quantity), 0), 0)) AS return_rate
FROM 
    item ir
LEFT JOIN 
    RankedReturns rr ON ir.i_item_sk = rr.sr_item_sk AND rr.return_rank = 1
LEFT JOIN 
    ItemSales is ON ir.i_item_sk = is.ws_item_sk
GROUP BY 
    ir.i_item_id, ir.i_item_desc
ORDER BY 
    return_rate DESC
LIMIT 10;
