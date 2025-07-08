
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS state_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        AVG(LENGTH(ca_city)) AS avg_city_length,
        LISTAGG(DISTINCT ca_street_type, ', ') AS unique_street_types
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demographic_count,
        AVG(cd_dep_count) AS avg_dependent_count,
        LISTAGG(DISTINCT cd_marital_status, ', ') AS marital_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
InventoryStats AS (
    SELECT 
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_quantity,
        MIN(inv_quantity_on_hand) AS min_quantity,
        MAX(inv_quantity_on_hand) AS max_quantity
    FROM 
        inventory
    GROUP BY 
        inv_warehouse_sk
),
SalesPerformance AS (
    SELECT
        d.d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    a.ca_state,
    a.state_count,
    a.avg_street_name_length,
    a.avg_city_length,
    a.unique_street_types,
    c.cd_gender,
    c.demographic_count,
    c.avg_dependent_count,
    c.marital_statuses,
    i.inv_warehouse_sk,
    i.total_quantity,
    i.min_quantity,
    i.max_quantity,
    s.d_year,
    s.total_sales,
    s.total_profit
FROM 
    AddressStats a
JOIN 
    CustomerDemographics c ON a.state_count > 50 
JOIN 
    InventoryStats i ON i.total_quantity > 1000 
JOIN 
    SalesPerformance s ON s.d_year = 2001 
ORDER BY 
    a.ca_state, c.cd_gender;
