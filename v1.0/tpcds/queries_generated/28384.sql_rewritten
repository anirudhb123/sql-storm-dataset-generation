WITH CustomerAddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_address_id,
        CONCAT_WS(', ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM 
        customer_address ca
),
GenderStatistics AS (
    SELECT 
        cd.cd_gender,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
SalesAggregate AS (
    SELECT 
        ws.ws_web_site_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_web_site_sk
)
SELECT 
    cab.ca_address_id,
    cab.full_address,
    gst.cd_gender,
    gst.customer_count,
    gst.avg_purchase_estimate,
    sa.total_net_profit,
    sa.total_orders
FROM 
    CustomerAddressDetails cab
JOIN 
    GenderStatistics gst ON EXISTS (
        SELECT 1 
        FROM customer c 
        WHERE c.c_current_addr_sk = cab.ca_address_sk 
        AND c.c_customer_sk IN (SELECT DISTINCT c_customer_sk FROM web_sales)
    )
JOIN 
    SalesAggregate sa ON sa.ws_web_site_sk = 1 
WHERE 
    cab.ca_state = 'CA' 
ORDER BY 
    gst.customer_count DESC, 
    sa.total_net_profit DESC;