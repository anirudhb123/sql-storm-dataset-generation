
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SaleSummary AS (
    SELECT 
        CASE 
            WHEN ws_bill_customer_sk IS NOT NULL THEN 'Web Sale'
            WHEN cs_bill_customer_sk IS NOT NULL THEN 'Catalog Sale'
            WHEN ss_customer_sk IS NOT NULL THEN 'Store Sale'
        END AS sale_type,
        c.c_customer_id,
        COUNT(DISTINCT ws_order_number) AS web_orders,
        COUNT(DISTINCT cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss_ticket_number) AS store_orders
    FROM 
        web_sales ws
    FULL OUTER JOIN 
        catalog_sales cs ON ws.ws_bill_customer_sk = cs.cs_bill_customer_sk
    FULL OUTER JOIN 
        store_sales ss ON ws.ws_bill_customer_sk = ss.ss_customer_sk
    JOIN 
        customer c ON c.c_customer_sk = ws.ws_bill_customer_sk OR c.c_customer_sk = cs.cs_bill_customer_sk OR c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.cd_gender,
    ss.sale_type,
    ss.web_orders,
    ss.catalog_orders,
    ss.store_orders,
    COALESCE(ss.web_orders, 0) + COALESCE(ss.catalog_orders, 0) + COALESCE(ss.store_orders, 0) AS total_orders
FROM 
    CustomerInfo ci
LEFT JOIN 
    SaleSummary ss ON ci.c_customer_id = ss.c_customer_id
WHERE 
    (ci.cd_gender = 'M' AND ci.cd_marital_status = 'S') 
    OR (ci.cd_gender = 'F' AND ci.cd_marital_status = 'M')
ORDER BY 
    total_orders DESC
LIMIT 100;
