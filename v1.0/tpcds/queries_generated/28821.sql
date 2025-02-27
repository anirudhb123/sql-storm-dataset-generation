
WITH AddressDetails AS (
    SELECT 
        ca_state,
        ca_city,
        ca_street_name,
        ca_street_type,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_state,
        ca_city,
        ca_street_name,
        ca_street_type,
        ca_street_number
),
Demographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        COUNT(*) AS demographic_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, 
        cd_marital_status, 
        cd_education_status
),
Sales AS (
    SELECT 
        ws_ship_date_sk,
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk, 
        ws_bill_customer_sk
),
FinalBenchmark AS (
    SELECT 
        ad.ca_state,
        ad.ca_city,
        ad.full_address,
        dem.cd_gender,
        dem.cd_marital_status,
        dem.total_purchase_estimate,
        sales.total_sales,
        sales.order_count
    FROM 
        AddressDetails ad
    JOIN 
        Demographics dem ON ad.ca_state = 'CA'  -- Filter for California
    JOIN 
        Sales sales ON sales.ws_bill_customer_sk = dem.cd_demo_sk
    WHERE 
        dem.cd_purchase_estimate > 1000  -- Only include customers with high purchase estimates
)
SELECT 
    ca_state,
    ca_city,
    full_address,
    cd_gender,
    cd_marital_status,
    total_purchase_estimate,
    total_sales,
    order_count
FROM 
    FinalBenchmark
ORDER BY 
    total_sales DESC, 
    total_purchase_estimate DESC
LIMIT 100;  -- Limit the output to top 100 results
