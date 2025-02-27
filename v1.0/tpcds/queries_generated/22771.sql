
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > (
            SELECT 
                AVG(ws1.ws_sales_price) 
            FROM 
                web_sales ws1 
            WHERE 
                ws1.ws_item_sk = ws.ws_item_sk
        )
),
HoldReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_return_amt) AS total_return_amt,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_returns
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
WebReturns AS (
    SELECT 
        wr.wr_item_sk,
        AVG(wr.wr_return_amt) AS avg_return_amt,
        SUM(wr.wr_return_quantity) AS total_web_return_quantity
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
FinalSales AS (
    SELECT 
        i.i_item_id,
        COALESCE(rs.ws_sales_price, 0) AS highest_web_price,
        COALESCE(hr.total_return_quantity, 0) AS total_catalog_returns,
        COALESCE(wr.avg_return_amt, 0) AS average_web_return
    FROM 
        item i
    LEFT JOIN 
        RankedSales rs ON i.i_item_sk = rs.ws_item_sk AND rs.price_rank = 1
    LEFT JOIN 
        HoldReturns hr ON i.i_item_sk = hr.cr_item_sk
    LEFT JOIN 
        WebReturns wr ON i.i_item_sk = wr.wr_item_sk
)
SELECT 
    fs.i_item_id,
    fs.highest_web_price,
    fs.total_catalog_returns,
    fs.average_web_return,
    CASE 
        WHEN fs.highest_web_price > 100 THEN 'High Value'
        WHEN fs.highest_web_price BETWEEN 50 AND 100 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS price_category
FROM 
    FinalSales fs
WHERE 
    (fs.total_catalog_returns IS NULL OR fs.total_catalog_returns > 5) AND
    fs.average_web_return <> 0
ORDER BY 
    fs.highest_web_price DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
