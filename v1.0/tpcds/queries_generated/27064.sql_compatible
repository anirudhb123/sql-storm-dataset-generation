
WITH AddressInfo AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        LENGTH(ca.ca_street_name) AS street_name_length,
        UPPER(ca.ca_city) AS upper_city,
        LOWER(ca.ca_state) AS lower_state
    FROM 
        customer_address ca
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS first_purchase_date,
        cd.cd_marital_status,
        cd.cd_gender
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
SalesSummary AS (
    SELECT 
        ws.ws_bill_customer_sk AS customer_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_purchased
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ai.full_address,
    ai.upper_city,
    ai.lower_state,
    ss.total_orders,
    ss.total_spent,
    ss.unique_items_purchased
FROM 
    CustomerInfo ci
JOIN 
    AddressInfo ai ON ci.c_customer_id = ai.ca_address_id
JOIN 
    SalesSummary ss ON ci.c_customer_id = ss.customer_id
WHERE 
    ai.ca_country = 'USA'
    AND ss.total_spent > 1000
ORDER BY 
    ss.total_spent DESC
LIMIT 100;
