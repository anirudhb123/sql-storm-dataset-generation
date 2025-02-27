
WITH sales_summary AS (
    SELECT 
        s.s_store_sk,
        s.ss_sold_date_sk,
        SUM(s.ss_sales_price) AS total_sales,
        COUNT(s.ss_ticket_number) AS total_transactions,
        AVG(s.ss_sales_price) AS avg_sales_price,
        COUNT(DISTINCT s.ss_customer_sk) AS unique_customers
    FROM 
        store_sales s
    JOIN 
        date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        s.s_store_sk, s.ss_sold_date_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(s.total_sales) AS total_sales,
        COUNT(s.total_transactions) AS total_transactions
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        sales_summary s ON c.c_customer_sk = s.s_store_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
final_report AS (
    SELECT 
        cs.cd_gender,
        cs.cd_marital_status,
        SUM(cs.total_sales) AS overall_sales,
        AVG(cs.total_transactions) AS avg_transactions
    FROM 
        customer_summary cs
    GROUP BY 
        cs.cd_gender, cs.cd_marital_status
)

SELECT 
    fr.cd_gender,
    fr.cd_marital_status,
    fr.overall_sales,
    fr.avg_transactions,
    RANK() OVER (ORDER BY fr.overall_sales DESC) AS sales_rank
FROM 
    final_report fr
ORDER BY 
    fr.overall_sales DESC;
