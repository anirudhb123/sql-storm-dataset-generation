
WITH sales_summary AS (
    SELECT 
        d.d_year AS year,
        d.d_month_seq AS month,
        SUM(COALESCE(ss.net_paid, 0)) AS total_sales,
        SUM(COALESCE(ss.ext_discount_amt, 0)) AS total_discount,
        COUNT(DISTINCT ss.ticket_number) AS total_transactions,
        AVG(ss.net_paid) AS avg_transaction_value,
        COUNT(DISTINCT ss.customer_sk) AS unique_customers
    FROM 
        date_dim d
    LEFT JOIN 
        store_sales ss ON ss.sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        d.d_year, d.d_month_seq
),
customer_demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.net_paid) AS total_spent,
        COUNT(DISTINCT ss.customer_sk) AS customer_count
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
final_report AS (
    SELECT 
        ss.year,
        ss.month,
        ss.total_sales,
        ss.total_discount,
        ss.total_transactions,
        ss.avg_transaction_value,
        ss.unique_customers,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.total_spent,
        cd.customer_count
    FROM 
        sales_summary ss
    LEFT JOIN 
        customer_demographics cd ON ss.year = EXTRACT(YEAR FROM CURRENT_DATE) AND ss.month = EXTRACT(MONTH FROM CURRENT_DATE)
)
SELECT 
    year,
    month,
    total_sales,
    total_discount,
    total_transactions,
    avg_transaction_value,
    unique_customers,
    cd_gender,
    cd_marital_status,
    total_spent,
    customer_count
FROM 
    final_report
ORDER BY 
    year DESC, month DESC;
