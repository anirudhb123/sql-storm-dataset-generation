
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_net_profit,
        cs.order_count
    FROM 
        CustomerSales cs
    WHERE 
        cs.sales_rank <= 10
),
ReturnsStats AS (
    SELECT 
        cr.returning_customer_sk,
        COUNT(DISTINCT cr.cr_order_number) AS return_count,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.returning_customer_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_net_profit,
    tc.order_count,
    COALESCE(rs.return_count, 0) AS return_count,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN tc.total_net_profit > 1000 THEN 'High Value'
        WHEN tc.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value
FROM 
    TopCustomers tc
LEFT JOIN 
    ReturnsStats rs ON tc.c_customer_sk = rs.returning_customer_sk
ORDER BY 
    tc.total_net_profit DESC;
