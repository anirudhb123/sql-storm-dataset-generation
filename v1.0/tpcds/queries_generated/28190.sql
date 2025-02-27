
WITH CustomerStatistics AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        AVG(cd_purchase_estimate) AS average_purchase_estimate,
        MIN(cd_credit_rating) AS lowest_credit_rating,
        MAX(cd_credit_rating) AS highest_credit_rating
    FROM 
        customer_demographics
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_gender
),
AddressStatistics AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS total_addresses,
        STRING_AGG(ca_city, ', ') AS cities
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
SalesStatistics AS (
    SELECT 
        sm.sm_type,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price) AS total_sales_value
    FROM 
        web_sales
    JOIN 
        ship_mode sm ON ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_type
)
SELECT 
    cs.cd_gender,
    cs.total_customers,
    cs.average_purchase_estimate,
    cs.lowest_credit_rating,
    cs.highest_credit_rating,
    as.ca_state,
    as.total_addresses,
    as.cities,
    ss.sm_type,
    ss.total_quantity_sold,
    ss.total_sales_value
FROM 
    CustomerStatistics cs
JOIN 
    AddressStatistics as ON 1=1  -- Cross join to pair all address statistics with customer stats
JOIN 
    SalesStatistics ss ON 1=1;  -- Cross join to pair all sales statistics with the result
