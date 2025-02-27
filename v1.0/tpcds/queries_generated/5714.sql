
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        cd.cd_gender = 'M' AND 
        cd.cd_marital_status = 'S' AND 
        cd.cd_education_status IN ('Bachelors', 'Masters')
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        total_sales,
        purchase_count,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rank
    FROM 
        customer_data c
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_education_status,
    tc.total_sales,
    tc.purchase_count
FROM 
    top_customers tc
WHERE 
    tc.rank <= 10
ORDER BY 
    total_sales DESC;
