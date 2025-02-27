
WITH CustomerSales AS (
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
SalesRanked AS (
    SELECT 
        c.customer_id,
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        RANK() OVER (ORDER BY (total_web_sales + total_catalog_sales + total_store_sales) DESC) AS sales_rank
    FROM 
        CustomerSales c
)
SELECT 
    cr.customer_id,
    cr.total_web_sales,
    cr.total_catalog_sales,
    cr.total_store_sales,
    cr.sales_rank,
    cd.cd_gender,
    cd.cd_age_group
FROM 
    SalesRanked cr
JOIN 
    customer_demographics cd ON cr.customer_id = cd.cd_demo_sk
WHERE 
    cr.sales_rank <= 100
ORDER BY 
    cr.sales_rank;
