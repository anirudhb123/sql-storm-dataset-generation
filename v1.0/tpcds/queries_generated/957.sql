
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk AS customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_returned,
        COUNT(sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
ItemsSold AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_sales_price) AS total_spent,
        COUNT(ws_order_number) AS sales_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
TotalReturnsPerCustomer AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cr.total_returned, 0) AS total_returned,
        COALESCE(is.total_spent, 0) AS total_spent,
        is.sales_count,
        CASE 
            WHEN COALESCE(is.total_spent, 0) = 0 THEN NULL
            ELSE ROUND(COALESCE(cr.total_returned, 0) / COALESCE(is.total_spent, 0) * 100, 2)
        END AS return_percentage
    FROM 
        customer c
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.customer_sk
    LEFT JOIN ItemsSold is ON c.c_customer_sk = is.customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    t.*,
    CASE 
        WHEN t.return_percentage IS NULL THEN 'No Sales'
        WHEN t.return_percentage > 25 THEN 'High Return Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    TotalReturnsPerCustomer t
JOIN 
    customer c ON t.c_customer_sk = c.c_customer_sk
WHERE 
    t.sales_count > 5
ORDER BY 
    t.return_percentage DESC NULLS LAST;
