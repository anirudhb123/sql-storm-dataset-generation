
WITH AddressStats AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        STRING_AGG(DISTINCT ca_street_name || ' ' || ca_street_number || ' ' || ca_street_type, ', ') AS all_street_names
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
CustomerStats AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(*) AS num_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesStats AS (
    SELECT 
        d_year,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_quantity) AS total_quantity_sold
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
)
SELECT 
    a.ca_city,
    a.unique_addresses,
    a.all_street_names,
    c.cd_gender,
    c.cd_marital_status,
    c.num_customers,
    c.avg_purchase_estimate,
    s.d_year,
    s.total_net_profit,
    s.total_quantity_sold
FROM 
    AddressStats a
JOIN 
    CustomerStats c ON c.num_customers > 100
JOIN 
    SalesStats s ON s.total_net_profit > 10000
WHERE 
    a.unique_addresses > 10
ORDER BY 
    s.d_year DESC, a.ca_city;
