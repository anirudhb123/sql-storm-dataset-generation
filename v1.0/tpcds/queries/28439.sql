
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COUNT(sr.sr_ticket_number) AS total_returns,
        COUNT(ws.ws_order_number) AS total_web_sales,
        COUNT(cs.cs_order_number) AS total_catalog_sales,
        COUNT(ss.ss_ticket_number) AS total_store_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, 
        cd.cd_purchase_estimate, cd.cd_credit_rating, ca.ca_city, ca.ca_state, ca.ca_country
),
ProcessedData AS (
    SELECT 
        full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        ca_city,
        ca_state,
        ca_country,
        total_returns,
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_web_sales DESC) AS web_sales_rank,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_catalog_sales DESC) AS catalog_sales_rank,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_store_sales DESC) AS store_sales_rank
    FROM 
        CustomerData
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_purchase_estimate,
    cd_credit_rating,
    ca_city,
    ca_state,
    ca_country,
    total_returns,
    total_web_sales,
    total_catalog_sales,
    total_store_sales,
    web_sales_rank,
    catalog_sales_rank,
    store_sales_rank
FROM 
    ProcessedData
WHERE 
    (web_sales_rank <= 10 OR catalog_sales_rank <= 10 OR store_sales_rank <= 10)
ORDER BY 
    ca_state, total_web_sales DESC, total_catalog_sales DESC, total_store_sales DESC;
