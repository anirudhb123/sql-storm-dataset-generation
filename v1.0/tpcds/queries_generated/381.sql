
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0
),
DailyReturns AS (
    SELECT
        sr_returned_date_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk
),
TopSellingItems AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_quantity) AS total_quantity_sold
    FROM 
        RankedSales rs
    WHERE 
        rs.profit_rank = 1
    GROUP BY 
        rs.ws_item_sk
    HAVING 
        SUM(rs.ws_quantity) > 100
)
SELECT 
    d.d_date AS sale_date,
    ti.i_item_desc AS item_description,
    tsi.total_quantity_sold,
    dr.total_returned,
    dr.total_return_amt,
    COALESCE(dr.total_returned, 0) AS unreturned_quantity
FROM 
    DailyReturns dr
FULL OUTER JOIN 
    date_dim d ON dr.sr_returned_date_sk = d.d_date_sk
INNER JOIN 
    TopSellingItems tsi ON tsi.ws_item_sk = ANY(ARRAY(SELECT DISTINCT ws_item_sk FROM web_sales))
INNER JOIN 
    item ti ON tsi.ws_item_sk = ti.i_item_sk
WHERE 
    d.d_year = 2023 
    AND d.d_month IN (1, 2, 3)
ORDER BY 
    sale_date DESC, total_quantity_sold DESC;
