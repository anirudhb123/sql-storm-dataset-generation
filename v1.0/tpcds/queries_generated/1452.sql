
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year >= 1980 AND c.c_birth_year <= 2000
    GROUP BY c.c_customer_id
), 

TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.order_count,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS rn
    FROM CustomerSales cs
    WHERE cs.sales_rank <= 10
),

ReturnData AS (
    SELECT 
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_amt_inc_tax) AS total_returned,
        COUNT(DISTINCT wr.wr_order_number) AS return_count
    FROM web_returns wr
    GROUP BY wr.wr_returning_customer_sk
)

SELECT 
    tc.c_customer_id,
    tc.total_sales,
    COALESCE(rd.total_returned, 0) AS total_returned,
    tc.order_count,
    rd.return_count,
    (tc.total_sales - COALESCE(rd.total_returned, 0)) AS net_sales
FROM TopCustomers tc
LEFT JOIN ReturnData rd ON tc.c_customer_id = rd.wr_returning_customer_sk
WHERE tc.total_sales > 5000
ORDER BY net_sales DESC;
