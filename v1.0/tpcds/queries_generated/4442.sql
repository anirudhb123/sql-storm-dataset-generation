
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
MonthlySales AS (
    SELECT 
        d_year,
        d_month_seq,
        SUM(ws_net_paid_inc_tax) AS total_sales
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year, d_month_seq
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_return_value, 0) AS total_return_value,
        COUNT(ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cr.return_count, cr.total_return_value
    ORDER BY 
        total_orders DESC
    LIMIT 10
)
SELECT 
    tc.c_customer_id,
    tc.return_count,
    tc.total_return_value,
    ms.total_sales,
    ROW_NUMBER() OVER (PARTITION BY ms.d_year ORDER BY tc.total_orders DESC) AS sales_rank
FROM 
    TopCustomers tc
JOIN 
    MonthlySales ms ON ms.d_month_seq = (SELECT d_month_seq FROM date_dim WHERE d_year = EXTRACT(YEAR FROM CURRENT_DATE) AND d_month_seq = ms.d_month_seq)
WHERE 
    tc.return_count > 0
ORDER BY 
    ms.total_sales DESC, tc.total_return_value DESC;
