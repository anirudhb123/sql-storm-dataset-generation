
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_return_time_sk,
        sr_item_sk,
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amt_inc_tax
    FROM 
        store_returns 
    GROUP BY 
        sr_returned_date_sk, sr_return_time_sk, sr_item_sk, sr_customer_sk
),
ItemSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales_amt
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
ReturnAnalysis AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(is.total_sold_quantity, 0) AS total_sold_quantity,
        CASE 
            WHEN COALESCE(is.total_sold_quantity, 0) = 0 THEN 0
            ELSE ROUND(COALESCE(cr.total_return_quantity, 0) * 100.0 / COALESCE(is.total_sold_quantity, 0), 2)
        END AS return_percentage
    FROM 
        item i
    LEFT JOIN 
        CustomerReturns cr ON i.i_item_sk = cr.sr_item_sk
    LEFT JOIN 
        ItemSales is ON i.i_item_sk = is.ws_item_sk
)
SELECT 
    r.i_item_id,
    r.i_item_desc,
    r.total_return_quantity,
    r.total_sold_quantity,
    r.return_percentage,
    CASE 
        WHEN r.return_percentage > 20 THEN 'High Return'
        WHEN r.return_percentage BETWEEN 10 AND 20 THEN 'Moderate Return'
        ELSE 'Low Return'
    END AS return_category
FROM 
    ReturnAnalysis r
ORDER BY 
    r.return_percentage DESC
LIMIT 100;
