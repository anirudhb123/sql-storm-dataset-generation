
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        COALESCE(ws.ws_ship_date_sk, cs.cs_ship_date_sk, ss.ss_sold_date_sk) AS sold_date_sk,
        COUNT(DISTINCT CASE WHEN ws.ws_customer_sk IS NOT NULL THEN ws.ws_order_number END) AS web_sales_count,
        COUNT(DISTINCT CASE WHEN cs.cs_customer_sk IS NOT NULL THEN cs.cs_order_number END) AS catalog_sales_count,
        COUNT(DISTINCT CASE WHEN ss.ss_customer_sk IS NOT NULL THEN ss.ss_ticket_number END) AS store_sales_count
    FROM 
        web_sales ws 
    FULL OUTER JOIN 
        catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk 
    FULL OUTER JOIN 
        store_sales ss ON ws.ws_item_sk = ss.ss_item_sk 
    GROUP BY 
        sold_date_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    sd.sold_date_sk,
    sd.web_sales_count,
    sd.catalog_sales_count,
    sd.store_sales_count
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesData sd ON ci.c_customer_id = sd.sold_date_sk
WHERE 
    ci.cd_gender = 'F'
ORDER BY 
    sd.web_sales_count DESC, sd.catalog_sales_count DESC, sd.store_sales_count DESC
LIMIT 100;
