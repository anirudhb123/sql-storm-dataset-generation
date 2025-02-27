
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
ReturnDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cr.total_returns,
        cr.total_return_amount,
        CASE 
            WHEN cr.total_returns IS NULL THEN 'No Returns'
            ELSE 'Returned'
        END AS return_status
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
),
SalesDetails AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
SalesReturnComparison AS (
    SELECT 
        rd.c_customer_id,
        rd.c_first_name,
        rd.c_last_name,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.order_count, 0) AS order_count,
        rd.total_returns,
        rd.total_return_amount,
        rd.return_status
    FROM 
        ReturnDetails rd
    LEFT JOIN 
        SalesDetails sd ON rd.c_customer_id = sd.ws_bill_customer_sk
)
SELECT 
    src.c_customer_id,
    src.c_first_name,
    src.c_last_name,
    src.total_sales,
    src.order_count,
    src.total_returns,
    src.total_return_amount,
    src.return_status,
    ROUND(COALESCE((src.total_return_amount / NULLIF(src.total_sales, 0)) * 100, 0), 2) AS return_percentage
FROM 
    SalesReturnComparison src
WHERE 
    (src.return_status = 'Returned' AND src.total_sales > 1000)
    OR (src.return_status = 'No Returns' AND src.total_sales < 500)
ORDER BY 
    src.total_return_amount DESC
LIMIT 100;
