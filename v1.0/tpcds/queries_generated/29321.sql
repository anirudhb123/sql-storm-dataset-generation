
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        SUM(CASE WHEN LENGTH(ca_street_name) > 30 THEN 1 ELSE 0 END) AS long_street_names,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_dep_count) AS max_dependents
    FROM 
        customer_demographics cd 
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_gender
),
WebSalesStats AS (
    SELECT 
        ws.web_site_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_sk
)
SELECT 
    a.ca_state,
    a.total_addresses,
    a.long_street_names,
    a.avg_street_name_length,
    c.cd_gender,
    c.total_customers,
    c.avg_purchase_estimate,
    c.max_dependents,
    w.total_orders,
    w.total_sales,
    w.avg_net_profit
FROM 
    AddressStats a
JOIN 
    CustomerStats c ON a.total_addresses > 100
JOIN 
    WebSalesStats w ON w.total_orders > 500
ORDER BY 
    a.total_addresses DESC, c.total_customers DESC;
