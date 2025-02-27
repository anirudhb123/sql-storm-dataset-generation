
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_address_id,
        ca_city,
        ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY LENGTH(ca_city) DESC) AS city_rank
    FROM 
        customer_address
),
FilteredCities AS (
    SELECT 
        ca_state,
        STRING_AGG(ca_city, ', ' ORDER BY city_rank) AS aggregated_cities
    FROM 
        RankedAddresses
    WHERE 
        city_rank <= 3
    GROUP BY 
        ca_state
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        fc.aggregated_cities
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        FilteredCities fc ON c.c_current_addr_sk IN (SELECT ca_address_sk FROM customer_address WHERE ca_state = fc.ca_state)
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.aggregated_cities,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_profit) AS total_profit
FROM 
    CustomerInfo ci
LEFT JOIN 
    web_sales ws ON ci.c_customer_id = ws.ws_bill_customer_sk
GROUP BY 
    ci.c_customer_id, ci.cd_gender, ci.cd_marital_status, ci.aggregated_cities
ORDER BY 
    total_profit DESC
LIMIT 10;
