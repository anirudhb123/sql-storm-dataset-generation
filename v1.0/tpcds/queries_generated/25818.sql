
WITH customer_info AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd_gender = 'M' THEN 'Mr. ' || c.c_first_name
            WHEN cd_gender = 'F' THEN 'Ms. ' || c.c_first_name
            ELSE c.c_first_name 
        END AS polite_name,
        d.d_date AS membership_date,
        cd.marital_status,
        cd.education_status,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN date_dim d ON c.c_first_shipto_date_sk = d.d_date_sk
),

sales_info AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_ship_date_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_ship_date_sk DESC) AS order_sequence
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_order_number, ws.ws_sales_price, ws.ws_quantity, ws.ws_ship_date_sk
),

combined_info AS (
    SELECT 
        ci.full_name,
        ci.polite_name,
        ci.membership_date,
        si.ws_order_number,
        si.total_sales,
        ci.marital_status,
        ci.education_status,
        ci.ca_city,
        ci.ca_state
    FROM 
        customer_info ci
    LEFT JOIN sales_info si ON ci.c_customer_id = si.ws_order_number
)

SELECT 
    polite_name,
    COUNT(ws_order_number) AS orders_count,
    SUM(total_sales) AS total_spent,
    AVG(total_sales) AS avg_order_value,
    MIN(membership_date) AS first_membership_date,
    MAX(membership_date) AS last_membership_date,
    marital_status,
    education_status,
    ca_city,
    ca_state
FROM 
    combined_info
GROUP BY 
    polite_name, marital_status, education_status, ca_city, ca_state
ORDER BY 
    total_spent DESC;
