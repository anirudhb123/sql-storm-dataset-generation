
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_ext_sales_price) AS total_web_sales, 
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales, 
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM customer_demographics cd
),
DailySales AS (
    SELECT 
        d.d_date_id, 
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY d.d_date_id
)
SELECT 
    cs.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cs.total_web_sales,
    cs.total_catalog_sales,
    cs.total_store_sales,
    ds.total_web_sales AS daily_web_sales,
    ds.total_catalog_sales AS daily_catalog_sales,
    ds.total_store_sales AS daily_store_sales
FROM CustomerSales cs
JOIN CustomerDemographics cd ON cs.c_customer_id = cd.cd_demo_sk
LEFT JOIN DailySales ds ON ds.d_date_id = (SELECT MAX(d_date_id) FROM date_dim);
