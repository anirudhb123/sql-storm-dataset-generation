
WITH address_summary AS (
    SELECT 
        ca_state, 
        ca_city, 
        COUNT(DISTINCT ca_address_sk) AS address_count,
        STRING_AGG(ca_street_name, ', ') AS street_names, 
        STRING_AGG(DISTINCT CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') AS full_addresses
    FROM 
        customer_address
    GROUP BY 
        ca_state, ca_city
),
customer_info AS (
    SELECT 
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(cd.cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
sales_summary AS (
    SELECT 
        w.w_warehouse_id, 
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    a.ca_state,
    a.ca_city,
    a.address_count,
    a.street_names,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_education_status,
    c.customer_count,
    c.total_purchase_estimate,
    s.w_warehouse_id,
    s.total_net_profit
FROM 
    address_summary a
JOIN 
    customer_info c ON a.ca_city = c.cd_city
JOIN 
    sales_summary s ON c.total_purchase_estimate > 100000
ORDER BY 
    a.ca_state, a.ca_city, c.cd_gender, s.w_warehouse_id;
