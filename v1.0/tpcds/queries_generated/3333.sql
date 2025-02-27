
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id, 
        cs.cd_gender,
        cs.total_sales,
        cs.order_count
    FROM 
        CustomerSales cs
    WHERE 
        cs.sales_rank <= 10
),
ReturnMetrics AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_returned_amount,
        COUNT(wr_order_number) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    tc.c_customer_id,
    tc.cd_gender,
    COALESCE(tr.total_returned_amount, 0) AS total_returned_amount,
    tc.total_sales,
    tc.order_count,
    CASE 
        WHEN tc.total_sales - COALESCE(tr.total_returned_amount, 0) > 0 THEN 'Profitable'
        ELSE 'Not Profitable'
    END AS profitability_status
FROM 
    TopCustomers tc
LEFT JOIN 
    ReturnMetrics tr ON tc.c_customer_id = tr.wr_returning_customer_sk
ORDER BY 
    tc.total_sales DESC;
