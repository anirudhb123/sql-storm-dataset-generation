
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        LENGTH(c.c_email_address) AS email_length
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
        SUM(ws_sales_price) AS total_spent,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.customer_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    ci.email_length,
    COALESCE(sd.total_spent, 0) AS total_spent,
    COALESCE(sd.order_count, 0) AS order_count,
    CASE 
        WHEN sd.total_spent IS NULL THEN 'NO PURCHASE'
        ELSE 
            CASE 
                WHEN sd.total_spent > 1000 THEN 'HIGH SPENDER'
                WHEN sd.total_spent BETWEEN 500 AND 1000 THEN 'MEDIUM SPENDER'
                ELSE 'LOW SPENDER' 
            END 
    END AS spending_category
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesData sd ON ci.c_customer_id = sd.ws_bill_customer_sk
ORDER BY 
    ci.ca_state, 
    ci.customer_name;
