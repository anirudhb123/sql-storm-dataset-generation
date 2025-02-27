
WITH EnhancedCustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        hd.hd_buy_potential,
        CONCAT('Address: ', ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address
    FROM 
        customer AS c
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics AS hd ON c.c_customer_sk = hd.hd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        e.c_customer_id,
        e.full_name,
        e.ca_city,
        e.ca_state,
        s.total_sales,
        s.total_orders,
        e.full_address
    FROM 
        EnhancedCustomerInfo AS e
    LEFT JOIN 
        SalesInfo AS s ON e.c_customer_id = s.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    total_sales,
    total_orders,
    full_address
FROM 
    FinalReport
ORDER BY 
    total_sales DESC
LIMIT 10;
