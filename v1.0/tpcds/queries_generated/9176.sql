
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count
    FROM 
        customer c
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
        LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
demographic_sales AS (
    SELECT 
        cd.cd_demo_sk,
        SUM(cs.total_web_sales) AS total_web_sales,
        SUM(cs.total_catalog_sales) AS total_catalog_sales,
        COUNT(DISTINCT cs.web_order_count) AS web_order_count,
        COUNT(DISTINCT cs.catalog_order_count) AS catalog_order_count
    FROM 
        customer_demographics cd
        LEFT JOIN customer_sales cs ON cd.cd_demo_sk = c.c_current_cdemo_sk 
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    cd.cd_gender,
    SUM(ds.total_web_sales) AS web_sales_by_gender,
    SUM(ds.total_catalog_sales) AS catalog_sales_by_gender,
    AVG(ds.web_order_count) AS avg_web_orders_per_customer,
    AVG(ds.catalog_order_count) AS avg_catalog_orders_per_customer
FROM 
    demographic_sales ds
    INNER JOIN customer_demographics cd ON ds.cd_demo_sk = cd.cd_demo_sk
GROUP BY 
    cd.cd_gender
ORDER BY 
    web_sales_by_gender DESC;
