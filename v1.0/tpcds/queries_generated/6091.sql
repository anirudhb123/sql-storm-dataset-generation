
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        SUM(cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) AS total_spending
    FROM 
        customer_sales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_purchase_estimate
)
SELECT 
    cd_gender,
    cd_marital_status,
    cd_education_status,
    COUNT(*) AS num_customers,
    AVG(total_spending) AS avg_spending,
    MAX(total_spending) AS max_spending,
    MIN(total_spending) AS min_spending
FROM 
    demographics
GROUP BY 
    cd_gender, 
    cd_marital_status, 
    cd_education_status
ORDER BY 
    avg_spending DESC;
