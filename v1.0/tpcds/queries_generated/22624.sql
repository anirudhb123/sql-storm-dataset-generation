
WITH RankedReturns AS (
    SELECT 
        sr.returned_date_sk, 
        sr.return_time_sk, 
        sr.item_sk, 
        sr.return_quantity, 
        sr.return_amt, 
        ROW_NUMBER() OVER (PARTITION BY sr.item_sk ORDER BY sr.returned_date_sk DESC) AS rn
    FROM 
        store_returns sr
    WHERE 
        sr.return_quantity > 0
),
ItemSales AS (
    SELECT 
        ws.item_sk,
        SUM(ws.quantity) AS total_sales_quantity,
        SUM(ws.net_paid) AS total_sales_amount,
        COUNT(DISTINCT ws.order_number) AS total_orders
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk > 0 
    GROUP BY 
        ws.item_sk
),
ReturnAggregate AS (
    SELECT 
        R.item_sk,
        SUM(R.return_quantity) AS total_return_quantity,
        SUM(R.return_amt) AS total_return_amount
    FROM 
        RankedReturns R
    WHERE 
        R.rn = 1 
    GROUP BY 
        R.item_sk
)
SELECT 
    I.i_item_id,
    COALESCE(SA.total_sales_quantity, 0) AS total_sales_quantity,
    COALESCE(SA.total_sales_amount, 0) AS total_sales_amount,
    COALESCE(RA.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(RA.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN COALESCE(SA.total_sales_quantity, 0) = 0 
        THEN NULL 
        ELSE (COALESCE(RA.total_return_quantity, 0) * 1.0 / COALESCE(SA.total_sales_quantity, 0)) * 100 
    END AS return_rate_percentage
FROM 
    item I
LEFT JOIN 
    ItemSales SA ON I.i_item_sk = SA.item_sk
LEFT JOIN 
    ReturnAggregate RA ON I.i_item_sk = RA.item_sk
WHERE 
    (COALESCE(SA.total_sales_quantity, 0) > 0 OR COALESCE(RA.total_return_quantity, 0) > 0)
ORDER BY 
    return_rate_percentage DESC NULLS LAST
LIMIT 50;
