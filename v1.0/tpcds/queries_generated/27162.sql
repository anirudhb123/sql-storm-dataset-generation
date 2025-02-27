
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(ca_street_name, ', ') AS all_street_names,
        STRING_AGG(DISTINCT ca_city, ', ') AS unique_cities
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
SalesStats AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(ws_ext_sales_price) AS avg_sales_price
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        COALESCE(s.total_net_profit, 0) AS total_net_profit,
        COALESCE(a.address_count, 0) AS address_count,
        COALESCE(a.all_street_names, 'N/A') AS street_names,
        COALESCE(a.unique_cities, 'N/A') AS cities
    FROM 
        customer c
    LEFT JOIN 
        SalesStats s ON c.c_customer_sk = s.ws_bill_cdemo_sk
    LEFT JOIN 
        AddressStats a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
)
SELECT 
    CONCAT(first_name, ' ', last_name) AS full_name,
    total_net_profit,
    address_count,
    street_names,
    cities,
    d_year
FROM 
    CustomerStats
WHERE 
    total_net_profit > 0
ORDER BY 
    total_net_profit DESC, full_name;
