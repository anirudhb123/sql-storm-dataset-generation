
WITH address_summary AS (
    SELECT 
        ca_city, 
        ca_state, 
        COUNT(DISTINCT ca_address_sk) AS address_count,
        STRING_AGG(DISTINCT ca_street_name || ' ' || ca_street_type, ', ') AS street_names
    FROM 
        customer_address
    WHERE 
        ca_country = 'USA'
    GROUP BY 
        ca_city, ca_state
),
customer_summary AS (
    SELECT 
        cd_demo_sk, 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        STRING_AGG(DISTINCT c_first_name || ' ' || c_last_name, ', ') AS customer_names,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer_demographics 
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status, cd_education_status
),
shipment_summary AS (
    SELECT 
        sm_ship_mode_id,
        sm_carrier,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    JOIN 
        ship_mode ON ws_ship_mode_sk = sm_ship_mode_sk
    GROUP BY 
        sm_ship_mode_id, sm_carrier
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.address_count,
    a.street_names,
    c.cd_gender,
    c.cd_marital_status,
    c.total_purchase_estimate,
    c.customer_names,
    s.sm_ship_mode_id,
    s.sm_carrier,
    s.total_orders,
    s.total_sales
FROM 
    address_summary AS a
JOIN 
    customer_summary AS c ON a.ca_city = c.cd_gender
JOIN 
    shipment_summary AS s ON c.cd_marital_status = s.sm_carrier
ORDER BY 
    a.ca_city, c.total_purchase_estimate DESC;
