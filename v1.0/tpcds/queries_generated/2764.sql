
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
),
StoresWithSales AS (
    SELECT 
        ss.s_store_sk,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM store_sales ss
    GROUP BY ss.s_store_sk
    HAVING SUM(ss.ss_net_paid) > 1000
),
ReturnsAnalysis AS (
    SELECT 
        sr_store_sk,
        COUNT(sr_return_quantity) AS total_returns,
        SUM(sr_net_loss) AS total_return_loss
    FROM store_returns sr
    GROUP BY sr_store_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    ts.total_store_sales,
    ts.total_transactions,
    ra.total_returns,
    ra.total_return_loss
FROM TopCustomers tc
LEFT JOIN StoresWithSales ts ON tc.order_count > 5
LEFT JOIN ReturnsAnalysis ra ON ra.sr_store_sk = ts.s_store_sk
WHERE tc.sales_rank <= 10
ORDER BY tc.total_sales DESC, ra.total_return_loss ASC;
