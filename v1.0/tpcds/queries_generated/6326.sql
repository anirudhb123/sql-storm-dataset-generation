
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
), demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT cs.c_customer_id) AS customer_count,
        AVG(cs.total_web_sales) AS avg_web_sales,
        AVG(cs.total_catalog_sales) AS avg_catalog_sales,
        AVG(cs.total_store_sales) AS avg_store_sales
    FROM 
        customer_sales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    cd.gender,
    cd.marital_status,
    cd.education_status,
    cd.customer_count,
    cd.avg_web_sales,
    cd.avg_catalog_sales,
    cd.avg_store_sales
FROM 
    demographics cd
WHERE 
    cd.customer_count > 100
ORDER BY 
    avg_web_sales DESC, avg_catalog_sales DESC, avg_store_sales DESC;
