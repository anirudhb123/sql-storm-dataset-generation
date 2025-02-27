
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_sales
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cs.total_sales
    FROM 
        customer_demographics cd
    JOIN customer_sales cs ON cd.cd_demo_sk = c.c_current_cdemo_sk
)
SELECT 
    cd_gender,
    cd_marital_status,
    cd_education_status,
    COUNT(*) AS num_customers,
    AVG(total_sales) AS avg_sales,
    SUM(total_sales) AS total_sales
FROM 
    demographics
GROUP BY 
    cd_gender, 
    cd_marital_status, 
    cd_education_status
ORDER BY 
    total_sales DESC
LIMIT 10;
