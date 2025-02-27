
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
DemographicDetails AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(c_customer_sk) AS customer_count
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender, 
        cd_marital_status, 
        cd_education_status
),
SalesSummary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY 
        ws.web_site_id
),
FinalReport AS (
    SELECT 
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country,
        dd.cd_gender,
        dd.cd_marital_status,
        dd.cd_education_status,
        dd.customer_count,
        ss.total_sales,
        ss.total_orders
    FROM 
        AddressDetails ad
    JOIN 
        DemographicDetails dd ON TRUE
    JOIN 
        SalesSummary ss ON TRUE
    ORDER BY 
        dd.customer_count DESC, ss.total_sales DESC
)
SELECT * FROM FinalReport
LIMIT 100;
