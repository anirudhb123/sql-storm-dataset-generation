
WITH AddressDetails AS (
    SELECT 
        ca.ca_address_id, 
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_zip,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_id, ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, ca.ca_city, ca.ca_state, ca.ca_zip
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        COUNT(c.c_customer_sk) AS total_customers
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate, cd.cd_credit_rating, cd.cd_dep_count
),
SalesSummary AS (
    SELECT 
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders_web,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders_catalog,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_orders_store
    FROM 
        web_sales ws
    FULL OUTER JOIN 
        catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
    FULL OUTER JOIN 
        store_sales ss ON ws.ws_item_sk = ss.ss_item_sk
),
FinalReport AS (
    SELECT 
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        ad.customer_count,
        cd.total_customers
    FROM 
        AddressDetails ad
    JOIN 
        CustomerDemographics cd ON ad.customer_count > 0
    JOIN 
        SalesSummary cs ON cd.total_customers > 0
)
SELECT * FROM FinalReport
WHERE total_web_sales > 10000 OR total_catalog_sales > 5000 OR total_store_sales > 7000
ORDER BY total_web_sales DESC, total_catalog_sales DESC, total_store_sales DESC;
