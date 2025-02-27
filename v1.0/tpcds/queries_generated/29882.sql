
WITH EnhancedCustomer AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd_gender = 'F' THEN 'Female'
            WHEN cd_gender = 'M' THEN 'Male'
            ELSE 'Other'
        END AS gender,
        cd.marital_status,
        cd.education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
RecentOrders AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ship_date_sk DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk >= DATEADD(month, -3, CAST(GETDATE() AS DATE))
    GROUP BY 
        ws.ws_ship_date_sk, ws.ws_item_sk
)
SELECT 
    ec.full_name,
    ec.gender,
    ec.marital_status,
    ec.education_status,
    ec.ca_city,
    ec.ca_state,
    ec.ca_country,
    ec.full_address,
    ro.total_quantity,
    ro.total_net_paid
FROM 
    EnhancedCustomer ec
LEFT JOIN 
    RecentOrders ro ON ec.c_customer_sk = ro.ws_item_sk
WHERE 
    ro.rn = 1
ORDER BY 
    ec.full_name ASC, ro.total_net_paid DESC;
