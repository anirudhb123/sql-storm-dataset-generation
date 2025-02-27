
WITH AddressDetails AS (
    SELECT 
        LOWER(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip)) AS full_address,
        ca_address_sk
    FROM 
        customer_address
),
DemographicDetails AS (
    SELECT 
        cd_demo_sk,
        CONCAT(cd_gender, '-', cd_marital_status, '-', cd_education_status) AS demographic_info
    FROM 
        customer_demographics
),
SalesDetails AS (
    SELECT 
        ws.bill_customer_sk,
        COUNT(ws.order_number) AS total_orders,
        SUM(ws.net_profit) AS total_net_profit,
        MAX(ws_sold_date_sk) AS last_order_date
    FROM 
        web_sales ws
    GROUP BY 
        ws.bill_customer_sk
)
SELECT 
    c.first_name,
    c.last_name,
    ad.full_address,
    dem.demographic_info,
    COALESCE(sd.total_orders, 0) AS total_orders,
    COALESCE(sd.total_net_profit, 0) AS total_net_profit,
    COALESCE(sd.last_order_date, 'No Orders') AS last_order_date
FROM 
    customer c
JOIN 
    AddressDetails ad ON c.current_addr_sk = ad.ca_address_sk
JOIN 
    DemographicDetails dem ON c.current_cdemo_sk = dem.cd_demo_sk
LEFT JOIN 
    SalesDetails sd ON c.c_customer_sk = sd.bill_customer_sk
WHERE 
    ad.full_address LIKE '%New York%'
ORDER BY 
    sd.total_net_profit DESC, c.last_name ASC;
