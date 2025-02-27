
WITH RECURSIVE SalesCTE AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws.ws_ext_sales_price) > 1000

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(cs.cs_ext_sales_price) > 500

    UNION ALL
 
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ss.ss_ext_sales_price) > 800
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
SalesSummary AS (
    SELECT 
        s.c_customer_sk,
        s.c_first_name,
        s.c_last_name,
        SUM(s.total_sales) AS overall_sales
    FROM 
        SalesCTE s
    GROUP BY 
        s.c_customer_sk, s.c_first_name, s.c_last_name
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    ss.overall_sales,
    CASE 
        WHEN ss.overall_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Exceeded'
    END AS sales_status
FROM 
    SalesSummary ss
JOIN 
    customer c ON ss.c_customer_sk = c.c_customer_sk
JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cd.customer_count > 0
ORDER BY 
    ss.overall_sales DESC;
