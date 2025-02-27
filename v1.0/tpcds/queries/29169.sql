
WITH AddressCounts AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        STRING_AGG(DISTINCT CONCAT(ca_city, ', ', ca_street_name, ' ', ca_street_number, ' ', ca_street_type), '; ') AS address_list
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
Demographics AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate > 500
),
SalesData AS (
    SELECT 
        ws_bill_cdemo_sk AS demo_sk,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
)
SELECT 
    a.ca_state,
    a.unique_addresses,
    a.address_list,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    s.total_sales
FROM 
    AddressCounts a
JOIN 
    Demographics d ON d.cd_demo_sk IN (SELECT DISTINCT c_current_cdemo_sk FROM customer WHERE c_customer_sk = d.cd_demo_sk)
JOIN 
    SalesData s ON a.unique_addresses > 100 AND s.demo_sk IN (SELECT DISTINCT c_current_cdemo_sk FROM customer WHERE c_customer_sk = s.demo_sk)
ORDER BY 
    a.ca_state;
