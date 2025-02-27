
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        COALESCE(NULLIF(cd.cd_credit_rating, ''), 'N/A') AS credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
Sales AS (
    SELECT 
        ws.ws_ship_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_customer_sk
)
SELECT 
    cu.c_customer_sk,
    cu.full_name,
    cu.cd_gender,
    cu.cd_marital_status,
    cu.cd_education_status,
    cu.total_sales,
    cu.order_count,
    ap.full_address,
    ap.ca_city,
    ap.ca_state,
    ap.ca_zip,
    ap.ca_country
FROM 
    CustomerDetails cu
JOIN 
    Sales s ON cu.c_customer_sk = s.ws_ship_customer_sk
JOIN 
    customer_address ca ON cu.c_current_addr_sk = ca.ca_address_sk
JOIN 
    AddressParts ap ON ca.ca_address_sk = ap.ca_address_sk
WHERE 
    cu.cd_purchase_estimate > 500 AND 
    cu.cd_gender = 'M' AND 
    ap.ca_state IN ('CA', 'NY', 'TX')
ORDER BY 
    total_sales DESC;
