
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS last_purchase_date
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        cd.cd_gender = 'M'
        AND cd.cd_marital_status = 'S'
        AND d.d_year = 2022
),
address_data AS (
    SELECT 
        ca.ca_address_id,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
),
combined_data AS (
    SELECT 
        cd.customer_id,
        cd.full_name,
        cd.last_purchase_date,
        ad.full_address,
        ad.ca_city,
        ad.ca_state
    FROM 
        customer_data cd
    JOIN 
        address_data ad ON cd.c_customer_id = ad.ca_address_id
)
SELECT 
    full_name,
    full_address,
    ca_city,
    ca_state,
    COUNT(*) OVER (PARTITION BY ca_state) AS customer_count,
    ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY last_purchase_date DESC) AS row_num
FROM 
    combined_data
WHERE 
    customer_count > 1
ORDER BY 
    ca_state, 
    last_purchase_date DESC;
