
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_returned_date_sk,
        sr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM 
        store_returns
),
ReturnStats AS (
    SELECT
        rr.sr_item_sk,
        SUM(rr.sr_return_quantity) AS total_returned,
        COUNT(*) AS return_count,
        MAX(rr.sr_returned_date_sk) AS last_return_date
    FROM 
        RankedReturns rr
    WHERE 
        rr.rn <= 5
    GROUP BY 
        rr.sr_item_sk
),
ItemSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    LEFT JOIN 
        ReturnStats rs ON ws.ws_item_sk = rs.sr_item_sk
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(is.total_sold, 0) AS total_sold,
    COALESCE(is.avg_sales_price, 0) AS avg_sales_price,
    COALESCE(rs.total_returned, 0) AS total_returned,
    COALESCE(rs.return_count, 0) AS return_count,
    CASE 
        WHEN COALESCE(is.total_sold, 0) = 0 THEN NULL
        ELSE (COALESCE(rs.total_returned, 0) * 1.0 / is.total_sold) * 100 
    END AS return_percentage,
    d.d_date
FROM 
    item i
LEFT JOIN 
    ItemSales is ON i.i_item_sk = is.ws_item_sk
LEFT JOIN 
    ReturnStats rs ON is.ws_item_sk = rs.sr_item_sk
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(d1.d_date_sk) FROM date_dim d1)
WHERE 
    i.i_rec_start_date <= d.d_date
    AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > d.d_date)
ORDER BY 
    return_percentage DESC
LIMIT 10;
