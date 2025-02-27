
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_sales_price) AS average_sales_price
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.customer_id, 
        cs.total_sales,
        cs.total_transactions,
        cs.average_sales_price,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
)
SELECT 
    tc.customer_id,
    tc.total_sales,
    tc.total_transactions,
    tc.average_sales_price,
    cd.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    TopCustomers tc
JOIN 
    income_band ib ON tc.hd_income_band_sk = ib.ib_income_band_sk
ORDER BY 
    tc.total_sales DESC
LIMIT 10;
