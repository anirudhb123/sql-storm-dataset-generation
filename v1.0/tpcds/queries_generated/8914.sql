
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT CASE WHEN sr.returned_date_sk IS NOT NULL THEN sr.ticket_number END) AS store_returns_count,
        COUNT(DISTINCT CASE WHEN cr.returned_date_sk IS NOT NULL THEN cr.order_number END) AS catalog_returns_count,
        COUNT(DISTINCT CASE WHEN wr.returned_date_sk IS NOT NULL THEN wr.order_number END) AS web_returns_count,
        SUM(ws_net_profit) AS total_web_sales_profit,
        SUM(cs_net_profit) AS total_catalog_sales_profit,
        SUM(ss_net_profit) AS total_store_sales_profit
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    cd_gender,
    cd_marital_status,
    cd_education_status,
    COUNT(c.c_customer_sk) AS customer_count,
    AVG(store_returns_count) AS avg_store_returns,
    AVG(catalog_returns_count) AS avg_catalog_returns,
    AVG(web_returns_count) AS avg_web_returns,
    SUM(total_web_sales_profit) AS total_web_sales,
    SUM(total_catalog_sales_profit) AS total_catalog_sales,
    SUM(total_store_sales_profit) AS total_store_sales
FROM 
    customer_stats cs
JOIN 
    customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
GROUP BY 
    cd_gender, cd_marital_status, cd_education_status
ORDER BY 
    customer_count DESC;
