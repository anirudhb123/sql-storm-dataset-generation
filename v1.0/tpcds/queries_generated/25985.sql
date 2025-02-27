
WITH address_summary AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        STRING_AGG(DISTINCT ca_street_name || ' ' || ca_street_type, ', ') AS street_names
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
customer_summary AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        STRING_AGG(DISTINCT c_first_name || ' ' || c_last_name, ', ') AS customer_names
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
sales_summary AS (
    SELECT 
        ws_ship_date_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.unique_addresses,
    a.street_names,
    c.cd_gender,
    c.customer_count,
    c.total_purchase_estimate,
    c.customer_names,
    s.ws_ship_date_sk,
    s.total_net_profit,
    s.total_orders
FROM 
    address_summary a
JOIN 
    customer_summary c ON a.ca_city = SUBSTRING(c.customer_names FROM POSITION(' ' IN c.customer_names) FOR 60)
JOIN 
    sales_summary s ON s.ws_ship_date_sk = 20230101 -- Replace with a specific date as needed
ORDER BY 
    a.ca_city, a.ca_state, c.cd_gender;
