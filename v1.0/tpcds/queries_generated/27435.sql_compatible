
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_purchase_estimate,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
PurchasedItems AS (
    SELECT 
        ws.ws_bill_customer_sk,
        i.i_item_desc,
        ws.ws_sales_price,
        ws.ws_quantity,
        (ws.ws_sales_price * ws.ws_quantity) AS total_price
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
),
Summary AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(pi.total_price) AS total_spent,
        COUNT(pi.i_item_desc) AS total_items_purchased
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        PurchasedItems pi ON cd.c_customer_id = pi.ws_bill_customer_sk
    GROUP BY 
        cd.full_name, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    total_spent,
    total_items_purchased,
    CASE 
        WHEN total_spent > 500 THEN 'High Value'
        WHEN total_spent BETWEEN 250 AND 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM 
    Summary
ORDER BY 
    total_spent DESC;
