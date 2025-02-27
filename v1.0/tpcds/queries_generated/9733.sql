
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_web_sales,
        SUM(cs.cs_sales_price) AS total_catalog_sales,
        SUM(ss.ss_sales_price) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
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
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_dep_count,
        cd.cd_dep_college_count,
        COUNT(DISTINCT cs.c_customer_id) as customer_count,
        SUM(cs.total_web_sales) AS total_web_sales_demo,
        SUM(cs.total_catalog_sales) AS total_catalog_sales_demo,
        SUM(cs.total_store_sales) AS total_store_sales_demo
    FROM 
        customer_demographics cd
    JOIN 
        CustomerSales cs ON cs.c_customer_id IN (
            SELECT c.c_customer_id 
            FROM customer c
            WHERE (c.c_current_cdemo_sk = cd.cd_demo_sk OR c.c_current_hdemo_sk = cd.cd_demo_sk)
        )
    GROUP BY 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_dep_count, 
        cd.cd_dep_college_count
) 
SELECT 
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_dep_count,
    cd_dep_college_count,
    customer_count,
    total_web_sales_demo,
    total_catalog_sales_demo,
    total_store_sales_demo
FROM 
    CustomerDemographics
ORDER BY 
    total_web_sales_demo DESC, 
    customer_count DESC
LIMIT 10;
