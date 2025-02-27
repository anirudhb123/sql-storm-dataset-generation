
WITH address_summary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS total_addresses,
        STRING_AGG(DISTINCT ca_city, ', ') AS unique_cities,
        STRING_AGG(DISTINCT ca_street_name, ', ') AS unique_streets,
        AVG(ca_gmt_offset) AS avg_gmt_offset
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
sales_summary AS (
    SELECT 
        ws_bill_addr_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_addr_sk
),
combined_summary AS (
    SELECT 
        a.ca_state,
        a.total_addresses,
        a.unique_cities,
        a.unique_streets,
        a.avg_gmt_offset,
        s.total_quantity_sold,
        s.total_net_profit,
        s.total_orders
    FROM 
        address_summary a
    JOIN 
        sales_summary s ON a.ca_address_id = s.ws_bill_addr_sk
)
SELECT 
    cs.ca_state,
    cs.total_addresses,
    cs.unique_cities,
    cs.unique_streets,
    cs.avg_gmt_offset,
    COALESCE(cs.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(cs.total_net_profit, 0.00) AS total_net_profit,
    COALESCE(cs.total_orders, 0) AS total_orders
FROM 
    combined_summary cs
ORDER BY 
    cs.total_net_profit DESC;
