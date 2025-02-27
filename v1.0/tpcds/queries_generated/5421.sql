
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(ws.ws_net_paid), 0) AS online_sales,
        COALESCE(SUM(ss.ss_net_paid), 0) AS in_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS online_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS in_store_order_count,
        COUNT(DISTINCT sr_ticket_number) AS store_returns_count,
        COUNT(DISTINCT cr_order_number) AS catalog_returns_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY 
        c.c_customer_id
),
demographic_info AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(cs.c_customer_id) AS total_customers,
        AVG(cs.online_sales) AS avg_online_sales,
        AVG(cs.in_store_sales) AS avg_in_store_sales
    FROM 
        customer_demographics cd
    JOIN 
        customer_sales cs ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    di.cd_gender,
    di.cd_marital_status,
    di.cd_education_status,
    di.total_customers,
    di.avg_online_sales,
    di.avg_in_store_sales,
    (di.avg_online_sales + di.avg_in_store_sales) AS total_avg_sales
FROM 
    demographic_info di
ORDER BY 
    total_avg_sales DESC
LIMIT 10;
