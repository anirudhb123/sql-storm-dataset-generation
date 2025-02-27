
WITH AddressStats AS (
    SELECT 
        ca_state, 
        COUNT(*) AS address_count, 
        STRING_AGG(DISTINCT ca_city, ', ') AS cities
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT
        cd_gender,
        COUNT(*) AS customer_count,
        SUM(cd_dep_count) AS total_dependents,
        STRING_AGG(DISTINCT cd_marital_status, ', ') AS marital_statuses
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_sales_price) AS total_sales_price,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        EXTRACT(YEAR FROM d_date) AS sale_year
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        EXTRACT(YEAR FROM d_date)
),
FinalStats AS (
    SELECT 
        a.ca_state,
        a.address_count,
        a.cities,
        c.cd_gender,
        c.customer_count,
        c.total_dependents,
        c.marital_statuses,
        s.sale_year,
        s.total_net_profit,
        s.total_sales_price,
        s.total_orders
    FROM 
        AddressStats a
    JOIN 
        CustomerStats c ON 1=1
    JOIN 
        SalesStats s ON s.sale_year = 2001 
)
SELECT 
    ca_state, 
    address_count, 
    cities, 
    cd_gender, 
    customer_count, 
    total_dependents, 
    marital_statuses, 
    sale_year, 
    total_net_profit, 
    total_sales_price, 
    total_orders
FROM 
    FinalStats
ORDER BY 
    ca_state, cd_gender, sale_year;
