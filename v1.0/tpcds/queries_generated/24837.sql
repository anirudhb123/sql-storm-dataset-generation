
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) as rn
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
    HAVING 
        SUM(ws_net_paid) > (SELECT AVG(ws_net_paid) FROM web_sales) 
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        s.total_sales,
        s.order_count 
    FROM 
        customer c
    JOIN 
        SalesCTE s ON c.c_customer_sk = s.ws_bill_customer_sk
    WHERE 
        s.rn <= 10
),
ReturnStats AS (
    SELECT 
        r.wr_returning_customer_sk,
        COUNT(r.wr_return_quantity) AS total_returns,
        SUM(r.wr_return_amt_inc_tax) AS total_return_value
    FROM 
        web_returns r
    GROUP BY 
        r.wr_returning_customer_sk
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_value, 0) AS total_return_value,
    tc.total_sales,
    CASE 
        WHEN tc.total_sales > 1000 THEN 'High Value Customer'
        WHEN tc.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer' 
    END AS customer_segment
FROM 
    TopCustomers tc
LEFT JOIN 
    ReturnStats rs ON tc.c_customer_id = rs.wr_returning_customer_sk
UNION ALL
SELECT 
    'Aggregate Totals' AS c_customer_id,
    NULL AS c_first_name,
    NULL AS c_last_name,
    SUM(COALESCE(rs.total_returns, 0)) AS total_returns,
    SUM(COALESCE(rs.total_return_value, 0)) AS total_return_value,
    SUM(tc.total_sales) AS total_sales,
    NULL AS customer_segment
FROM 
    TopCustomers tc
LEFT JOIN 
    ReturnStats rs ON tc.c_customer_id = rs.wr_returning_customer_sk
WHERE 
    tc.total_sales IS NOT NULL
ORDER BY 
    customer_segment, total_sales DESC;
