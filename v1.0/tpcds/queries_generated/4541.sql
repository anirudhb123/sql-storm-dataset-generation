
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        sds.ws_bill_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        sds.total_profit,
        sds.order_count
    FROM 
        SalesData sds
    JOIN 
        customer c ON sds.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        sds.profit_rank <= 10
),
ReturnedSales AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt_inc_tax) AS total_returned,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    tc.c_first_name, 
    tc.c_last_name, 
    tc.c_email_address, 
    tc.total_profit AS customer_total_profit,
    COALESCE(rs.total_returned, 0) AS total_returned,
    tc.order_count AS customer_order_count,
    rs.return_count AS return_count,
    CASE 
        WHEN rs.return_count IS NOT NULL THEN 'Yes'
        ELSE 'No'
    END AS has_returns
FROM 
    TopCustomers tc
LEFT JOIN 
    ReturnedSales rs ON tc.ws_bill_customer_sk = rs.w_returning_customer_sk
ORDER BY 
    tc.total_profit DESC;
