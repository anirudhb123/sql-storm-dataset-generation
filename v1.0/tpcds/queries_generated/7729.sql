
WITH sales_summary AS (
    SELECT 
        d.d_year AS sales_year,
        d.d_month AS sales_month,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_sales_price) AS avg_transaction_value
    FROM 
        store_sales ss
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        s.s_state = 'CA' 
        AND d.d_year BETWEEN 2020 AND 2023
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        d.d_year, d.d_month
),
monthly_change AS (
    SELECT 
        sales_year,
        sales_month,
        total_sales,
        total_transactions,
        avg_transaction_value,
        LAG(total_sales) OVER (ORDER BY sales_year, sales_month) AS previous_month_sales,
        total_sales - LAG(total_sales) OVER (ORDER BY sales_year, sales_month) AS sales_change
    FROM 
        sales_summary
)
SELECT 
    sales_year,
    sales_month,
    total_sales,
    total_transactions,
    avg_transaction_value,
    COALESCE(ROUND((sales_change / NULLIF(previous_month_sales, 0)) * 100, 2), 0) AS sales_growth_percentage
FROM 
    monthly_change
ORDER BY 
    sales_year, sales_month;
