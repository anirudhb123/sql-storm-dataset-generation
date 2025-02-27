
WITH sales_data AS (
    SELECT 
        d.d_year,
        SUM(ss.net_paid) AS total_sales,
        COUNT(DISTINCT ss.customer_sk) AS unique_customers,
        COUNT(DISTINCT ss.ticket_number) AS total_transactions,
        AVG(ss.net_paid) AS average_transaction_value
    FROM 
        store_sales ss
    JOIN 
        date_dim d ON ss.sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
),
customer_data AS (
    SELECT 
        cd_demo.gender,
        cd_demo.education_status,
        cd_demo.marital_status,
        SUM(sd.total_sales) AS sales_by_demographics,
        COUNT(DISTINCT sd.unique_customers) AS unique_customers_by_demographics
    FROM 
        sales_data sd
    JOIN 
        customer c ON c.customer_sk = sd.customer_sk
    JOIN 
        customer_demographics cd_demo ON c.current_cdemo_sk = cd_demo.cd_demo_sk
    GROUP BY 
        cd_demo.gender, cd_demo.education_status, cd_demo.marital_status
),
performance_benchmark AS (
    SELECT 
        gender,
        education_status,
        marital_status,
        sales_by_demographics,
        unique_customers_by_demographics,
        RANK() OVER (ORDER BY sales_by_demographics DESC) AS sales_rank
    FROM 
        customer_data
)
SELECT 
    pb.gender,
    pb.education_status,
    pb.marital_status,
    pb.sales_by_demographics,
    pb.unique_customers_by_demographics,
    pb.sales_rank
FROM 
    performance_benchmark pb
WHERE 
    pb.sales_rank <= 10
ORDER BY 
    pb.sales_by_demographics DESC;
