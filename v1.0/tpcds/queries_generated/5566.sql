
WITH CustomerReturns AS (
    SELECT 
        sr.returned_date_sk, 
        sr.return_time_sk, 
        sr.item_sk, 
        sr.customer_sk, 
        SUM(sr.return_quantity) AS total_returned_quantity,
        SUM(sr.return_amt) AS total_returned_amount,
        SUM(sr.return_tax) AS total_returned_tax
    FROM 
        store_returns sr
    GROUP BY 
        sr.returned_date_sk, 
        sr.return_time_sk, 
        sr.item_sk, 
        sr.customer_sk
),
SalesData AS (
    SELECT 
        ws.sold_date_sk, 
        ws.item_sk, 
        SUM(ws.quantity) AS total_sold_quantity,
        SUM(ws.net_paid) AS total_sales_amount
    FROM 
        web_sales ws
    GROUP BY 
        ws.sold_date_sk, 
        ws.item_sk
),
AggregatedData AS (
    SELECT 
        cr.returned_date_sk, 
        sd.sold_date_sk, 
        cr.item_sk,
        cr.customer_sk, 
        cr.total_returned_quantity,
        sd.total_sold_quantity,
        cr.total_returned_amount,
        sd.total_sales_amount,
        CASE 
            WHEN sd.total_sold_quantity > 0 THEN 
                (cr.total_returned_quantity::decimal / sd.total_sold_quantity) * 100
            ELSE 0 
        END AS return_rate_percentage
    FROM 
        CustomerReturns cr
    JOIN 
        SalesData sd ON cr.item_sk = sd.item_sk AND cr.returned_date_sk = sd.sold_date_sk
)
SELECT 
    ad.customer_sk, 
    COUNT(DISTINCT ad.item_sk) AS distinct_items_returned,
    SUM(ad.total_returned_quantity) AS total_returned_quantity,
    SUM(ad.total_returned_amount) AS total_returned_amount,
    SUM(ad.total_sold_quantity) AS total_sold_quantity,
    SUM(ad.total_sales_amount) AS total_sales_amount,
    AVG(ad.return_rate_percentage) AS avg_return_rate_percentage
FROM 
    AggregatedData ad
GROUP BY 
    ad.customer_sk
ORDER BY 
    total_sales_amount DESC;
