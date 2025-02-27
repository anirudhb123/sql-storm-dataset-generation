
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_credit_rating, 
        SUM(ss.ss_net_paid) AS total_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
AddressInfo AS (
    SELECT 
        ca.ca_address_id, 
        ca.ca_city, 
        ca.ca_state, 
        COUNT(ca.ca_address_sk) AS address_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_id, ca.ca_city, ca.ca_state
),
SalesPerformance AS (
    SELECT 
        cd.cd_gender, 
        cd.cd_marital_status, 
        SUM(CASE WHEN cs.cs_sold_date_sk IS NOT NULL THEN 1 ELSE 0 END) AS catalog_sales_count,
        SUM(CASE WHEN ws.ws_sold_date_sk IS NOT NULL THEN 1 ELSE 0 END) AS web_sales_count,
        SUM(ss.ss_quantity) AS total_store_sales
    FROM 
        customer_demographics cd
    LEFT JOIN 
        catalog_sales cs ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    LEFT JOIN 
        web_sales ws ON cd.cd_demo_sk = ws.ws_bill_cdemo_sk
    LEFT JOIN 
        store_sales ss ON cd.cd_demo_sk = ss.ss_cdemo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cs.c_customer_id,
    cs.cd_gender,
    cs.cd_marital_status,
    ai.ca_city,
    ai.ca_state,
    COUNT(ai.address_count) AS address_count,
    cs.total_sales,
    sp.catalog_sales_count,
    sp.web_sales_count,
    sp.total_store_sales
FROM 
    CustomerSummary cs
JOIN 
    AddressInfo ai ON cs.c_customer_id = (SELECT CONCAT('CUST', ai.ca_address_id) FROM customer c JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk WHERE c.c_customer_id = cs.c_customer_id LIMIT 1)
JOIN 
    SalesPerformance sp ON cs.cd_gender = sp.cd_gender AND cs.cd_marital_status = sp.cd_marital_status
GROUP BY 
    cs.c_customer_id, cs.cd_gender, cs.cd_marital_status, ai.ca_city, ai.ca_state, cs.total_sales, sp.catalog_sales_count, sp.web_sales_count, sp.total_store_sales
ORDER BY 
    total_sales DESC
LIMIT 100;
