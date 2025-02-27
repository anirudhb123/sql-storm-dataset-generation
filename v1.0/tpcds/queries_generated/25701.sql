
WITH AddressStatistics AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        AVG(CAST(ca_zip AS INT)) AS avg_zip,
        MAX(CHAR_LENGTH(ca_street_name)) AS max_street_length,
        MIN(CHAR_LENGTH(ca_street_name)) AS min_street_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerGenderStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS gender_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesPerformance AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count,
        MAX(ws_ship_date_sk) AS last_sale_date
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)

SELECT 
    A.ca_state,
    A.address_count,
    A.avg_zip,
    A.max_street_length,
    A.min_street_length,
    G.cd_gender,
    G.gender_count,
    G.avg_purchase_estimate,
    G.total_dependents,
    S.total_profit,
    S.order_count,
    S.last_sale_date
FROM 
    AddressStatistics A
JOIN 
    CustomerGenderStats G ON A.ca_state = (SELECT ca_state FROM customer_address WHERE ca_address_sk = G.cd_demo_sk)
LEFT JOIN 
    SalesPerformance S ON S.ws_bill_customer_sk = (SELECT c_customer_sk FROM customer WHERE c_customer_id = G.cd_demo_sk)
ORDER BY 
    A.ca_state, G.cd_gender;
