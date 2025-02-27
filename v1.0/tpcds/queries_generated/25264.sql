
WITH Address_CTE AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number != '' 
                    THEN CONCAT(', Suite ', TRIM(ca_suite_number)) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
Demographics_CTE AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        CONCAT(TRIM(cd_gender), ' ', TRIM(cd_marital_status), ' ', TRIM(cd_education_status)) AS demographic_description
    FROM 
        customer_demographics
),
Sales_Summary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    GROUP BY 
        ws.web_site_id
)
SELECT 
    a.full_address,
    a.ca_city,
    a.ca_state,
    d.demographic_description,
    s.total_net_profit,
    s.total_orders,
    s.avg_order_value
FROM 
    Address_CTE a
JOIN 
    Demographics_CTE d ON d.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_current_addr_sk = a.ca_address_sk LIMIT 1)
JOIN 
    Sales_Summary s ON s.web_site_id = (SELECT w.web_site_id FROM web_site w WHERE w.web_site_sk = (SELECT ws.ws_web_site_sk FROM web_sales ws WHERE ws.ws_ship_addr_sk = a.ca_address_sk LIMIT 1))
ORDER BY 
    a.ca_city, a.ca_state, s.total_net_profit DESC;
