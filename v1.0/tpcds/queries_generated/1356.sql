
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c 
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.total_orders,
        ROW_NUMBER() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_web_sales > 1000
),
CustomerReturns AS (
    SELECT 
        wr.refunded_customer_sk,
        SUM(wr.wr_return_amt) AS total_returned
    FROM 
        web_returns wr
    GROUP BY 
        wr.refunded_customer_sk
),
FinalReport AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.c_first_name,
        hvc.c_last_name,
        hvc.total_web_sales,
        hvc.total_orders,
        COALESCE(cr.total_returned, 0) AS total_returns,
        (hvc.total_web_sales - COALESCE(cr.total_returned, 0)) AS net_sales
    FROM 
        HighValueCustomers hvc
    LEFT JOIN 
        CustomerReturns cr ON hvc.c_customer_sk = cr.refunded_customer_sk
)
SELECT 
    fr.c_customer_sk,
    fr.c_first_name,
    fr.c_last_name,
    fr.total_web_sales,
    fr.total_orders,
    fr.total_returns,
    fr.net_sales,
    CASE 
        WHEN fr.net_sales > 5000 THEN 'High Value'
        WHEN fr.net_sales BETWEEN 1000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    FinalReport fr
ORDER BY 
    fr.net_sales DESC;
