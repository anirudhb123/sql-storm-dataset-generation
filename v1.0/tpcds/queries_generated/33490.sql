
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk AS customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        CAST(NULL AS INTEGER) AS parent_customer_id
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year >= 1980

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        ch.customer_id
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        CustomerHierarchy ch ON ch.customer_id = c.c_current_hdemo_sk
)

, SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        CustomerHierarchy ch ON ws.ws_ship_customer_sk = ch.customer_id
    GROUP BY 
        ws.web_site_id
)

SELECT 
    w.w_warehouse_id,
    w.w_warehouse_name,
    COALESCE(sd.total_net_profit, 0) AS total_net_profit,
    COALESCE(sd.total_orders, 0) AS total_orders,
    COUNT(DISTINCT ca.ca_address_id) AS total_addresses
FROM 
    warehouse w
LEFT JOIN 
    SalesData sd ON w.w_warehouse_sk = sd.web_site_id
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk IN (SELECT ch.customer_id FROM CustomerHierarchy ch)
GROUP BY 
    w.w_warehouse_id, w.w_warehouse_name
HAVING 
    COUNT(DISTINCT sd.total_orders) > 0 AND SUM(COALESCE(sd.total_net_profit, 0)) > 1000
ORDER BY 
    total_net_profit DESC;
