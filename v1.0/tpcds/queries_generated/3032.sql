
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TotalReturns AS (
    SELECT 
        ws_item_sk, 
        SUM(COALESCE(wr_return_quantity, 0)) AS total_return_quantity,
        SUM(COALESCE(wr_return_amt, 0)) AS total_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        ws_item_sk
),
ItemsWithReturns AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(tr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(tr.total_return_amt, 0) AS total_return_amt
    FROM 
        item i
    LEFT JOIN 
        TotalReturns tr ON i.i_item_sk = tr.ws_item_sk
),
BestSellingItems AS (
    SELECT 
        r.ws_item_sk,
        SUM(r.ws_quantity) AS total_quantity_sold,
        SUM(r.ws_sales_price) AS total_sales_value,
        AVG(r.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales r
    GROUP BY 
        r.ws_item_sk
)
SELECT 
    ibi.i_item_sk,
    ibi.i_item_desc,
    bsi.total_quantity_sold,
    bsi.total_sales_value,
    bsi.avg_net_profit,
    ibi.total_return_quantity,
    ibi.total_return_amt
FROM 
    ItemsWithReturns ibi
JOIN 
    BestSellingItems bsi ON ibi.i_item_sk = bsi.ws_item_sk
WHERE 
    bsi.total_quantity_sold > 10 
    AND (ibi.total_return_quantity > 0 OR ibi.total_return_amt > 0)
ORDER BY 
    avg_net_profit DESC,
    total_sales_value DESC
LIMIT 50;
