
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(sr_return_quantity, 0)) AS total_returned_quantity,
        SUM(COALESCE(sr_return_amt, 0)) AS total_returned_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
), 
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        ROW_NUMBER() OVER(PARTITION BY ws.ws_bill_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
    HAVING 
        SUM(ws.ws_sales_price) > 100
)
SELECT 
    cr.c_customer_id,
    sd.total_sales,
    sd.order_count,
    sd.avg_sales_price,
    cr.total_returned_quantity,
    cr.total_returned_amount,
    CASE
        WHEN cr.total_returned_quantity IS NOT NULL AND cr.total_returned_quantity > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status
FROM 
    CustomerReturns cr
FULL OUTER JOIN 
    SalesData sd ON cr.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_customer_sk = sd.ws_bill_customer_sk)
WHERE 
    (cr.total_returned_quantity > 5 OR sd.order_count > 2)
ORDER BY 
    cr.total_returned_amount DESC NULLS LAST;
