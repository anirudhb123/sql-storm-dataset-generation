
WITH AddressInfo AS (
    SELECT 
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(ca_street_name) AS street_name_length,
        LOWER(ca_city) AS lower_city
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c_first_name,
        c_last_name,
        UPPER(CONCAT(c_first_name, ' ', c_last_name)) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        LENGTH(c_first_name) + LENGTH(c_last_name) AS name_length
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT 
    ai.ca_city,
    ai.ca_state,
    ai.full_address,
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    si.total_quantity_sold,
    si.total_net_profit,
    (CASE 
        WHEN ai.lower_city LIKE 'new%' THEN 'Starts with New City' 
        ELSE 'Other City' 
     END) AS city_category
FROM 
    AddressInfo ai
JOIN 
    CustomerInfo ci ON ai.full_address LIKE CONCAT('%', ci.c_first_name, '%')
LEFT JOIN 
    SalesInfo si ON si.ws_item_sk = (SELECT MIN(i_item_sk) FROM item)
WHERE 
    ai.street_name_length > 5 
ORDER BY 
    ci.name_length DESC, si.total_net_profit DESC
LIMIT 100;
