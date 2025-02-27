
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.total_transactions,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS rnk
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    tc.c_customer_sk, 
    tc.c_first_name, 
    tc.c_last_name,
    tc.total_sales,
    tc.total_transactions
FROM 
    TopCustomers tc
WHERE 
    tc.rnk <= 10;

WITH DailySales AS (
    SELECT 
        dd.d_date,
        SUM(ss.ss_ext_sales_price) AS daily_total_sales,
        COUNT(ss.ss_order_number) AS daily_transactions
    FROM 
        store_sales ss
    JOIN 
        date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    GROUP BY 
        dd.d_date
),
AverageDailySales AS (
    SELECT 
        AVG(daily_total_sales) AS avg_daily_sales,
        AVG(daily_transactions) AS avg_daily_transactions
    FROM 
        DailySales
)
SELECT 
    ads.avg_daily_sales, 
    ads.avg_daily_transactions
FROM 
    AverageDailySales ads;
