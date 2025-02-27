
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 365
),
CustomerReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt_inc_tax) AS total_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
CombinedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COALESCE(cr.total_returned, 0) AS total_returned,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        CASE 
            WHEN COALESCE(cr.total_returned, 0) > 0 THEN 'Has Returns'
            ELSE 'No Returns'
        END AS return_status
    FROM 
        web_sales ws
    LEFT JOIN 
        CustomerReturns cr ON ws.ws_item_sk = cr.wr_item_sk
    GROUP BY 
        ws.ws_item_sk
),
FinalResults AS (
    SELECT 
        cs.ws_item_sk,
        cs.total_sold,
        cs.total_net_paid,
        cs.total_returned,
        cs.total_return_amt,
        cs.return_status,
        (cs.total_net_paid - cs.total_return_amt) AS net_revenue,
        CASE 
            WHEN cs.total_sold > 0 THEN (cs.total_returned * 1.0 / cs.total_sold) * 100
            ELSE 0
        END AS return_percentage
    FROM 
        CombinedSales cs
)
SELECT 
    f.item_sk,
    f.total_sold,
    f.total_net_paid,
    f.net_revenue,
    f.return_status,
    f.return_percentage
FROM 
    FinalResults f
JOIN 
    item i ON f.ws_item_sk = i.i_item_sk
WHERE 
    (f.total_sold > 100 AND f.net_revenue > 5000.00)
    OR (f.return_percentage > 10)
ORDER BY 
    f.net_revenue DESC
LIMIT 10;
