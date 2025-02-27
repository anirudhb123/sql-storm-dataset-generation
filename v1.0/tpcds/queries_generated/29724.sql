
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_sk) AS unique_addresses,
        AVG(LENGTH(CONCAT_WS(' ', ca_street_number, ca_street_name, ca_street_type, ca_suite_number))) AS avg_address_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS total_customers,
        AVG(cd_dep_count) AS avg_dependencies,
        STRING_AGG(DISTINCT CONCAT(c_first_name, ' ', c_last_name), ', ') AS sample_customers
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        CASE
            WHEN ws_ship_date_sk IS NOT NULL THEN 'web_sales'
            WHEN ss_sold_date_sk IS NOT NULL THEN 'store_sales'
            ELSE 'catalog_sales'
        END AS sales_channel,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    FULL OUTER JOIN 
        store_sales ON ws_order_number = ss_order_number
    FULL OUTER JOIN 
        catalog_sales ON ws_order_number = cs_order_number
    GROUP BY 
        sales_channel
)
SELECT 
    a.ca_state,
    a.unique_addresses,
    a.avg_address_length,
    c.cd_gender,
    c.total_customers,
    c.avg_dependencies,
    c.sample_customers,
    s.sales_channel,
    s.total_profit,
    s.total_orders
FROM 
    AddressStats a
JOIN 
    CustomerStats c ON a.ca_state IN (SELECT DISTINCT ca_state FROM customer_address)
JOIN 
    SalesStats s ON TRUE
ORDER BY 
    a.ca_state, c.cd_gender, s.sales_channel;
