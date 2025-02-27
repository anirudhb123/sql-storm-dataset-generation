
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Mr. ' || c.c_last_name
            WHEN cd.cd_gender = 'F' THEN 'Ms. ' || c.c_last_name 
            ELSE c.c_last_name 
        END AS salutation
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
    FROM 
        customer_address ca
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        cd.full_name,
        cd.salutation,
        ad.full_address,
        sd.total_orders,
        sd.total_revenue
    FROM 
        CustomerDetails cd
    JOIN 
        SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
    JOIN 
        AddressDetails ad ON cd.c_current_addr_sk = ad.ca_address_sk
)
SELECT 
    *,
    CASE 
        WHEN total_revenue > 1000 THEN 'High Value Customer'
        WHEN total_revenue BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM 
    FinalReport
ORDER BY 
    total_revenue DESC;
