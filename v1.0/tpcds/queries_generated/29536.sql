
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS unique_addresses,
        STRING_AGG(DISTINCT ca_city, ', ') AS cities,
        STRING_AGG(DISTINCT ca_street_name || ' ' || ca_street_number || ' ' || ca_street_type, '; ') AS full_addresses
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS num_customers,
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        STRING_AGG(DISTINCT CONCAT(c_first_name, ' ', c_last_name), ', ') AS customer_names
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        d_year,
        SUM(ss_net_profit) AS total_net_profit,
        AVG(ss_net_paid_inc_tax) AS avg_net_paid,
        STRING_AGG(DISTINCT ws_item_sk::text, ', ') as sold_items
    FROM 
        store_sales
    JOIN 
        date_dim ON ss_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
)
SELECT 
    a.ca_state,
    a.unique_addresses,
    a.cities,
    a.full_addresses,
    c.cd_gender,
    c.num_customers,
    c.total_purchase_estimate,
    c.customer_names,
    s.d_year,
    s.total_net_profit,
    s.avg_net_paid,
    s.sold_items
FROM 
    AddressStats a
JOIN 
    CustomerStats c ON c.num_customers > 0
JOIN 
    SalesStats s ON s.total_net_profit > 0
ORDER BY 
    a.ca_state, c.cd_gender, s.d_year;
