
WITH AddressAnalysis AS (
    SELECT 
        ca_state,
        ca_city,
        COUNT(*) AS address_count,
        STRING_AGG(DISTINCT CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') AS full_addresses
    FROM 
        customer_address
    GROUP BY 
        ca_state, ca_city
),
CustomerAnalysis AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        STRING_AGG(CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesStats AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        AA.ca_state,
        AA.ca_city,
        CA.cd_gender,
        CA.cd_marital_status,
        SA.total_sales,
        SA.order_count,
        AA.address_count,
        CA.customer_names,
        CA.total_purchase_estimate
    FROM 
        AddressAnalysis AA
    JOIN 
        CustomerAnalysis CA ON CA.cd_gender IS NOT NULL
    LEFT JOIN 
        SalesStats SA ON SA.ws_bill_customer_sk = (SELECT c_customer_sk FROM customer WHERE c_customer_id = CA.customer_names ORDER BY c_customer_sk LIMIT 1)
)
SELECT 
    ca_state, 
    ca_city, 
    cd_gender, 
    cd_marital_status, 
    total_sales, 
    order_count, 
    address_count, 
    customer_names, 
    total_purchase_estimate
FROM 
    FinalReport
ORDER BY 
    total_sales DESC;
