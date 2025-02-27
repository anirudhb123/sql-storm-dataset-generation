
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
), 
customer_demo AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate 
    FROM 
        customer_demographics cd
    INNER JOIN customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
sales_summary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(cs.c_customer_id) AS customer_count,
        SUM(cs.total_web_sales) AS total_web_sales,
        SUM(cs.total_catalog_sales) AS total_catalog_sales,
        SUM(cs.total_store_sales) AS total_store_sales,
        (SUM(cs.total_web_sales) + SUM(cs.total_catalog_sales) + SUM(cs.total_store_sales)) AS total_sales
    FROM 
        customer_sales cs
    INNER JOIN customer_demo cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    sd.cd_gender,
    sd.cd_marital_status,
    sd.customer_count,
    sd.total_web_sales,
    sd.total_catalog_sales,
    sd.total_store_sales,
    sd.total_sales,
    RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
FROM 
    sales_summary sd
WHERE 
    sd.total_sales > 0
ORDER BY 
    sd.total_sales DESC;
