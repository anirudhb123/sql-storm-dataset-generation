
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE cs.total_sales > 1000
),
ReturnStatistics AS (
    SELECT 
        sr_returning_customer_sk,
        COUNT(sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_returned_value
    FROM store_returns
    GROUP BY sr_returning_customer_sk
),
CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(rs.return_count, 0) AS return_count,
        COALESCE(rs.total_returned_value, 0) AS total_returned_value
    FROM customer c
    LEFT JOIN ReturnStatistics rs ON c.c_customer_sk = rs.sr_returning_customer_sk
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_sales,
    hvc.order_count,
    cr.return_count,
    cr.total_returned_value,
    CASE 
        WHEN cr.total_returned_value > (0.1 * hvc.total_sales) THEN 'High Return Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM HighValueCustomers hvc
LEFT JOIN CustomerReturns cr ON hvc.c_customer_sk = cr.c_customer_sk
ORDER BY hvc.sales_rank;
