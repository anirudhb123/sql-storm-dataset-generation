
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        INITCAP(ca_city) AS formatted_city,
        UPPER(ca_state) AS uppercase_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
demographics_summary AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics
    JOIN 
        customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY 
        cd_gender
),
inventory_summary AS (
    SELECT 
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory
    GROUP BY 
        inv_warehouse_sk
),
sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT 
    pa.ca_address_sk,
    pa.full_address,
    pa.formatted_city,
    pa.uppercase_state,
    pa.ca_zip,
    pa.ca_country,
    ds.cd_gender,
    ds.customer_count,
    ds.avg_purchase_estimate,
    is.total_quantity AS warehouse_inventory,
    ss.total_sales_quantity,
    ss.total_net_profit
FROM 
    processed_addresses pa
JOIN 
    demographics_summary ds ON ds.customer_count > 100
LEFT JOIN 
    inventory_summary is ON pa.ca_address_sk = is.inv_warehouse_sk
LEFT JOIN 
    sales_summary ss ON ss.ws_item_sk = pa.ca_address_sk
WHERE 
    pa.ca_country ILIKE 'USA'
ORDER BY 
    ds.customer_count DESC, 
    ss.total_net_profit DESC
LIMIT 100;
