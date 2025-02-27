
WITH CustomerAddressData AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
DemographicData AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer_demographics
),
SalesData AS (
    SELECT 
        ws_item_sk,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CombinedData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        a.full_address,
        a.ca_city,
        a.ca_state,
        d.cd_gender,
        d.cd_marital_status,
        s.order_count,
        s.total_quantity,
        s.total_sales
    FROM 
        customer c
    JOIN 
        CustomerAddressData a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        DemographicData d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN 
        SalesData s ON c.c_customer_sk = s.ws_item_sk
)
SELECT 
    customer_name,
    full_address,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    COALESCE(order_count, 0) AS order_count,
    COALESCE(total_quantity, 0) AS total_quantity,
    COALESCE(total_sales, 0.00) AS total_sales,
    CONCAT('Total Sales: $', FORMAT(COALESCE(total_sales, 0.00), 2)) AS sales_summary
FROM 
    CombinedData
WHERE 
    cd_gender = 'F'
ORDER BY 
    total_sales DESC
LIMIT 100;
