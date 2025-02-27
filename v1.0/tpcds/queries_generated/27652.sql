
WITH AddressInfo AS (
    SELECT 
        ca_state,
        CONCAT(ca_city, ', ', ca_street_name, ' ', ca_street_number, ' ', ca_zip) AS full_address,
        COUNT(*) AS total_addresses
    FROM 
        customer_address
    GROUP BY 
        ca_state, ca_city, ca_street_name, ca_street_number, ca_zip
),
DemographicsInfo AS (
    SELECT 
        cd_gender,
        CASE 
            WHEN cd_income_band_sk BETWEEN 1 AND 3 THEN 'Low Income'
            WHEN cd_income_band_sk BETWEEN 4 AND 6 THEN 'Medium Income'
            ELSE 'High Income'
        END AS income_category,
        COUNT(*) AS demo_count
    FROM 
        household_demographics
    JOIN 
        customer_demographics ON hd_income_band_sk = cd_demo_sk
    GROUP BY 
        cd_gender, income_category
),
SalesInfo AS (
    SELECT 
        ws_bill_addr_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_addr_sk
)
SELECT 
    ai.ca_state,
    ai.full_address,
    di.cd_gender,
    di.income_category,
    si.total_sales,
    si.total_orders
FROM 
    AddressInfo ai
JOIN 
    DemographicsInfo di ON ai.ca_state = 'CA' -- Focus on California
LEFT JOIN 
    SalesInfo si ON ai.ca_address_id = (SELECT ca_address_id FROM customer_address WHERE ca_address_sk = si.ws_bill_addr_sk)
WHERE 
    ai.total_addresses > 10 AND di.demo_count > 5
ORDER BY 
    ai.total_addresses DESC, si.total_sales DESC;
