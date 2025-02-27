
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_sales_price) AS average_sales_price,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY ss.ss_net_paid_inc_tax) AS sales_75th_percentile,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status,
        DATE_TRUNC('month', d.d_date) AS sales_month
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND 
        d.d_month_seq BETWEEN 1 AND 12
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, sales_month
),
top_customers AS (
    SELECT 
        customer_id,
        total_sales,
        total_transactions,
        average_sales_price,
        sales_75th_percentile,
        gender,
        marital_status,
        sales_month
    FROM 
        sales_summary
    WHERE 
        total_sales > 1000
),
ranked_customers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY sales_month ORDER BY total_sales DESC) AS sales_rank
    FROM 
        top_customers
)
SELECT 
    customer_id,
    total_sales,
    total_transactions,
    average_sales_price,
    sales_75th_percentile,
    gender,
    marital_status,
    sales_month
FROM 
    ranked_customers
WHERE 
    sales_rank <= 10
ORDER BY 
    sales_month, total_sales DESC;
