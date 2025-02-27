
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS rnk
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                               AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        c.c_customer_id
),
RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_store_sales,
        cs.total_transactions,
        RANK() OVER (ORDER BY cs.total_store_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    INNER JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
)
SELECT 
    rc.c_customer_id,
    rc.total_store_sales,
    rc.total_transactions,
    rc.sales_rank,
    COALESCE(band.ib_lower_bound, 0) AS income_lower_bound,
    COALESCE(band.ib_upper_bound, 0) AS income_upper_bound,
    CASE 
        WHEN rc.sales_rank <= 5 THEN 'Top Customer'
        ELSE 'Regular Customer' 
    END AS customer_category
FROM 
    RankedCustomers rc
LEFT JOIN 
    household_demographics hd ON rc.c_customer_id = hd.hd_demo_sk
LEFT JOIN 
    income_band band ON hd.hd_income_band_sk = band.ib_income_band_sk
WHERE 
    rc.sales_rank <= 10
ORDER BY 
    rc.sales_rank;
