
WITH address_summary AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(ca_address_id) AS total_addresses,
        STRING_AGG(DISTINCT ca_street_name, ', ') AS unique_streets,
        STRING_AGG(DISTINCT ca_street_type, ', ') AS street_types
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
customer_summary AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS total_customers,
        STRING_AGG(DISTINCT c_first_name || ' ' || c_last_name, ', ') AS customer_names
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
sales_summary AS (
    SELECT 
        d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.total_addresses,
    a.unique_streets,
    a.street_types,
    c.cd_gender,
    c.total_customers,
    c.customer_names,
    s.d_year,
    s.total_sales,
    s.avg_net_profit
FROM 
    address_summary a
JOIN 
    customer_summary c ON c.total_customers > 0
JOIN 
    sales_summary s ON s.total_sales > 0
ORDER BY 
    a.ca_city, a.ca_state, c.cd_gender, s.d_year;
