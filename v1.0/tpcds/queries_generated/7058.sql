
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesByDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cs.total_web_sales) AS total_web_sales,
        SUM(cs.total_catalog_sales) AS total_catalog_sales,
        SUM(cs.total_store_sales) AS total_store_sales
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = c.c_customer_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
SalesAnalysis AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        (total_web_sales + total_catalog_sales + total_store_sales) AS total_sales,
        (SELECT COUNT(*) FROM customer c WHERE c.c_current_cdemo_sk = cd.cd_demo_sk) AS customer_count
    FROM 
        SalesByDemographics cd
)
SELECT 
    ca.ca_city,
    SUM(sa.total_sales) AS total_sales_by_city,
    AVG(sa.customer_count) AS avg_customers_per_demo,
    COUNT(DISTINCT sa.cd_gender) AS unique_genders,
    COUNT(DISTINCT sa.cd_marital_status) AS unique_marital_statuses
FROM 
    SalesAnalysis sa
JOIN 
    customer c ON sa.c_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY 
    ca.ca_city
ORDER BY 
    total_sales_by_city DESC
LIMIT 10;
