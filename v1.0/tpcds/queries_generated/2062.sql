
WITH CustomerReturns AS (
    SELECT 
        sr.returned_date_sk,
        sr.return_time_sk,
        sr.return_item_sk,
        sr.return_quantity,
        sr.return_amt,
        sr.customer_sk,
        c.first_name,
        c.last_name,
        c.current_cdemo_sk,
        cd.gender,
        cd.marital_status,
        cd.education_status,
        ROW_NUMBER() OVER (PARTITION BY sr.customer_sk ORDER BY sr.returned_date_sk DESC) AS rn
    FROM 
        store_returns sr
    JOIN 
        customer c ON sr.customer_sk = c.customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
TopReturns AS (
    SELECT 
        cr.first_name,
        cr.last_name,
        cr.return_item_sk,
        cr.return_quantity,
        cr.return_amt,
        cr.rn
    FROM 
        CustomerReturns cr
    WHERE 
        cr.rn = 1
)
SELECT 
    tr.first_name,
    tr.last_name,
    tr.return_quantity,
    tr.return_amt,
    sd.total_quantity,
    sd.total_sales,
    (CASE 
        WHEN sd.order_count > 0 THEN (tr.return_amt / sd.total_sales) * 100 
        ELSE NULL 
     END) AS return_percentage
FROM 
    TopReturns tr
JOIN 
    SalesData sd ON tr.return_item_sk = sd.ws_item_sk
WHERE 
    tr.return_quantity > (
        SELECT AVG(return_quantity) 
        FROM CustomerReturns 
        WHERE customer_sk = tr.customer_sk
    )
ORDER BY 
    return_percentage DESC NULLS LAST;
