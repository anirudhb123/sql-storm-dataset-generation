
WITH DemographicData AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip,
        c.c_email_address,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_spent,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
JoinedData AS (
    SELECT 
        dd.c_customer_id,
        dd.full_name,
        dd.cd_gender,
        dd.cd_marital_status,
        dd.ca_city,
        dd.ca_state,
        dd.ca_country,
        dd.ca_zip,
        dd.c_email_address,
        sd.total_spent,
        sd.order_count
    FROM 
        DemographicData dd
    LEFT JOIN 
        SalesData sd ON dd.c_customer_id = sd.ws_bill_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    ca_city,
    ca_state,
    ca_country,
    ca_zip,
    c_email_address,
    COALESCE(total_spent, 0) AS total_spent,
    COALESCE(order_count, 0) AS order_count,
    CASE 
        WHEN total_spent IS NULL THEN 'No Purchases'
        WHEN total_spent < 100 THEN 'Low Spend'
        WHEN total_spent BETWEEN 100 AND 500 THEN 'Medium Spend'
        ELSE 'High Spend'
    END AS spending_category
FROM 
    JoinedData
ORDER BY 
    total_spent DESC;
