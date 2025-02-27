
WITH address_summary AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        COUNT(DISTINCT ca_address_sk) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_street_number, 
        ca_street_name, 
        ca_street_type, 
        ca_city, 
        ca_state, 
        ca_zip
),
demographics_summary AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents,
        cd_demo_sk
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, 
        cd_marital_status, 
        cd_demo_sk
),
sales_summary AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
)
SELECT 
    da.full_address,
    da.ca_city,
    da.ca_state,
    da.ca_zip,
    dm.cd_gender,
    dm.cd_marital_status,
    dm.avg_purchase_estimate,
    dm.total_dependents,
    ss.total_sales_quantity,
    ss.total_net_profit
FROM 
    address_summary da
JOIN 
    customer c ON c.c_current_addr_sk = (SELECT ca_address_sk FROM customer_address WHERE CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) = da.full_address LIMIT 1)
JOIN 
    demographics_summary dm ON c.c_current_cdemo_sk = dm.cd_demo_sk
LEFT JOIN 
    sales_summary ss ON c.c_customer_sk = ss.ws_bill_cdemo_sk
ORDER BY 
    da.ca_state, 
    da.ca_city, 
    dm.cd_gender;
