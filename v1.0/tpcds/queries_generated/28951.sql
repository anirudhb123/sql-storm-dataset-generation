
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesDetails AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedDetails AS (
    SELECT 
        cd.c_customer_id,
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.full_address,
        COALESCE(sd.total_profit, 0) AS total_profit,
        COALESCE(sd.order_count, 0) AS order_count
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        SalesDetails sd ON cd.c_customer_id = sd.ws_bill_customer_sk
)
SELECT 
    full_address,
    COUNT(c_customer_id) AS customer_count,
    AVG(total_profit) AS avg_profit,
    SUM(order_count) AS total_orders
FROM 
    CombinedDetails
GROUP BY 
    full_address
ORDER BY 
    customer_count DESC, avg_profit DESC
LIMIT 10;
