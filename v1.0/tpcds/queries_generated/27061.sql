
WITH AddressSummary AS (
    SELECT 
        ca_state,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        STRING_AGG(DISTINCT ca_city, ', ') AS cities_list
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesData AS (
    SELECT 
        sm_ship_mode_id,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    JOIN 
        ship_mode ON ws_ship_mode_sk = sm_ship_mode_sk
    GROUP BY 
        sm_ship_mode_id
)
SELECT 
    a.ca_state,
    a.avg_street_name_length,
    a.unique_addresses,
    a.cities_list,
    c.cd_gender,
    c.cd_marital_status,
    c.total_dependents,
    c.avg_purchase_estimate,
    s.sm_ship_mode_id,
    s.total_orders,
    s.total_sales
FROM 
    AddressSummary a
JOIN 
    CustomerDemographics c ON c.total_dependents > 0
JOIN 
    SalesData s ON s.total_sales > 0
ORDER BY 
    a.ca_state, c.cd_gender, s.total_sales DESC;
