
WITH customer_stats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(CASE WHEN cs.sold_date_sk IS NOT NULL THEN 1 ELSE 0 END) AS total_catalog_sales,
        SUM(CASE WHEN ws.sold_date_sk IS NOT NULL THEN 1 ELSE 0 END) AS total_web_sales,
        SUM(CASE WHEN ss.sold_date_sk IS NOT NULL THEN 1 ELSE 0 END) AS total_store_sales,
        COUNT(DISTINCT cr.order_number) AS total_catalog_returns,
        COUNT(DISTINCT wr.order_number) AS total_web_returns,
        COUNT(DISTINCT sr.ticket_number) AS total_store_returns
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        catalog_returns cr ON c.c_customer_sk = cr.cr_refunded_customer_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_refunded_customer_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    AVG(total_catalog_sales) AS avg_catalog_sales,
    AVG(total_web_sales) AS avg_web_sales,
    AVG(total_store_sales) AS avg_store_sales,
    SUM(total_catalog_returns) AS total_catalog_returns,
    SUM(total_web_returns) AS total_web_returns,
    SUM(total_store_returns) AS total_store_returns
FROM 
    customer_stats
JOIN 
    customer_demographics cd ON customer_stats.c_customer_id = cd.cd_demo_sk
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
ORDER BY 
    avg_catalog_sales DESC, avg_web_sales DESC, avg_store_sales DESC;
