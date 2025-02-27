
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS num_return_transactions
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighReturnCustomers AS (
    SELECT 
        c.customer_sk,
        c.first_name,
        c.last_name,
        cr.total_returns,
        cr.num_return_transactions
    FROM 
        CustomerReturns cr
    INNER JOIN 
        customer_demographics c ON cr.c_customer_sk = c.cd_demo_sk
    WHERE 
        cr.total_returns > (SELECT AVG(total_returns) FROM CustomerReturns)
        AND c.cd_gender = 'F'
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
Comparison AS (
    SELECT 
        hrc.first_name,
        hrc.last_name,
        hrc.total_returns,
        hrc.num_return_transactions,
        COALESCE(sd.total_sales, 0) AS total_sales,
        sd.total_orders
    FROM 
        HighReturnCustomers hrc
    LEFT JOIN 
        SalesData sd ON hrc.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_orders = 0 THEN 'No Orders'
        ELSE 'Orders Present'
    END AS orders_status,
    CASE 
        WHEN total_returns > total_sales THEN 'Higher Returns'
        ELSE 'Normal Returns'
    END AS return_status
FROM 
    Comparison
ORDER BY 
    total_returns DESC, total_sales DESC;
