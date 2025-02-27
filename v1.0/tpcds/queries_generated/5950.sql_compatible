
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        d.d_year
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2018 AND 2023
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, d.d_year
),
average_sales AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        AVG(total_sales) AS avg_sales,
        AVG(purchase_count) AS avg_purchase_count
    FROM 
        customer_sales
    GROUP BY 
        cd_gender, cd_marital_status, cd_education_status
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.purchase_count,
        ROW_NUMBER() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    JOIN 
        average_sales avg_sales ON cs.cd_gender = avg_sales.cd_gender
    WHERE 
        cs.total_sales > avg_sales.avg_sales
)
SELECT 
    c.c_customer_id,
    cs.total_sales,
    cs.purchase_count,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_education_status
FROM 
    top_customers cs
JOIN 
    customer c ON cs.c_customer_sk = c.c_customer_sk
WHERE 
    cs.sales_rank <= 10
ORDER BY 
    cs.cd_gender, cs.total_sales DESC;
