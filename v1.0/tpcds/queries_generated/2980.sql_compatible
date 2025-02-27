
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_current_addr_sk IS NOT NULL
    GROUP BY c.c_customer_id
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id, 
        cs.total_sales,
        cs.order_count,
        cd.cd_gender,
        cd.cd_marital_status
    FROM CustomerSales cs
    JOIN customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    WHERE cs.sales_rank <= 10
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.order_count,
    tc.cd_gender,
    tc.cd_marital_status,
    COALESCE(SUM(sr.sr_return_amt), 0) AS total_returns,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_count
FROM TopCustomers tc
LEFT JOIN store_returns sr ON tc.c_customer_id = sr.sr_customer_sk
GROUP BY 
    tc.c_customer_id,
    tc.total_sales,
    tc.order_count,
    tc.cd_gender,
    tc.cd_marital_status
ORDER BY 
    tc.total_sales DESC;
