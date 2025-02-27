
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
StoreSales AS (
    SELECT 
        ss.ss_customer_sk,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS tickets_count
    FROM store_sales ss
    GROUP BY ss.ss_customer_sk
),
TotalSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        COALESCE(cs.total_web_sales, 0) AS web_sales,
        COALESCE(ss.total_store_sales, 0) AS store_sales,
        (COALESCE(cs.total_web_sales, 0) + COALESCE(ss.total_store_sales, 0)) AS total_sales
    FROM CustomerSales cs
    FULL OUTER JOIN StoreSales ss ON cs.c_customer_sk = ss.ss_customer_sk
),
SalesRanked AS (
    SELECT 
        ts.c_customer_sk,
        ts.c_first_name,
        ts.c_last_name,
        ts.web_sales,
        ts.store_sales,
        ts.total_sales,
        RANK() OVER (ORDER BY ts.total_sales DESC) AS sales_rank
    FROM TotalSales ts
),
HighValueCustomers AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.c_first_name,
        hvc.c_last_name,
        hvc.total_sales,
        CASE
            WHEN hvc.total_sales > 1000 THEN 'Platinum'
            WHEN hvc.total_sales BETWEEN 500 AND 1000 THEN 'Gold'
            ELSE 'Silver'
        END AS customer_tier
    FROM SalesRanked hvc
    WHERE hvc.total_sales > 0
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_sales,
    hvc.customer_tier
FROM HighValueCustomers hvc
WHERE hvc.sales_rank <= 10
ORDER BY hvc.total_sales DESC;
