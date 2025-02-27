
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesPerformance AS (
    SELECT 
        ci.c_customer_id,
        SUM(CASE WHEN ws.ws_sold_date_sk IS NOT NULL THEN ws.ws_net_paid ELSE 0 END) AS online_sales,
        SUM(CASE WHEN ss.ss_sold_date_sk IS NOT NULL THEN ss.ss_net_paid ELSE 0 END) AS store_sales
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        web_sales ws ON ci.c_customer_id = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON ci.c_customer_id = ss.ss_customer_sk
    GROUP BY 
        ci.c_customer_id
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    SUM(sp.online_sales) AS total_online_sales,
    SUM(sp.store_sales) AS total_store_sales,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country
FROM 
    CustomerInfo ci
JOIN 
    SalesPerformance sp ON ci.c_customer_id = sp.c_customer_id
GROUP BY 
    ci.full_name, ci.cd_gender, ci.cd_marital_status, ci.ca_city, ci.ca_state, ci.ca_country
ORDER BY 
    total_online_sales DESC, total_store_sales DESC;
