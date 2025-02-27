
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(ss_total_sales, 0) AS total_sales,
        COALESCE(ws_total_sales, 0) AS total_web_sales,
        COALESCE(cs_total_sales, 0) AS total_catalog_sales,
        COALESCE(NULLIF(ss_total_sales, 0), NULLIF(ws_total_sales, 0), NULLIF(cs_total_sales, 0), 0) * 0 AS any_sales_flag
    FROM 
        customer c
    LEFT JOIN (
        SELECT 
            ss_customer_sk,
            SUM(ss_net_paid) AS ss_total_sales
        FROM 
            store_sales
        GROUP BY 
            ss_customer_sk
    ) ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN (
        SELECT 
            ws_bill_customer_sk,
            SUM(ws_net_paid) AS ws_total_sales
        FROM 
            web_sales
        GROUP BY 
            ws_bill_customer_sk
    ) ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN (
        SELECT 
            cs_bill_customer_sk,
            SUM(cs_net_paid) AS cs_total_sales
        FROM 
            catalog_sales
        GROUP BY 
            cs_bill_customer_sk
    ) cs ON c.c_customer_sk = cs.cs_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status
    FROM 
        customer_demographics cd
    WHERE
        cd.cd_demo_sk IN (SELECT DISTINCT c_current_cdemo_sk FROM customer WHERE c_current_cdemo_sk IS NOT NULL)
),
AddressCounts AS (
    SELECT 
        ca_county, 
        COUNT(ca_address_sk) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_county
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    ROUND(AVG(cs.total_sales) OVER (PARTITION BY cd.cd_gender), 2) AS avg_sales_by_gender,
    ac.address_count,
    (CASE 
        WHEN cs.total_sales > 1000 THEN 'High Value'
        WHEN cs.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END) AS customer_value_category
FROM 
    CustomerSales cs
JOIN 
    CustomerDemographics cd ON cs.c_customer_sk = cd.cd_demo_sk
LEFT JOIN 
    AddressCounts ac ON cs.c_customer_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = cs.c_customer_sk)
WHERE 
    cs.total_sales IS NOT NULL
ORDER BY 
    cs.c_customer_sk;
