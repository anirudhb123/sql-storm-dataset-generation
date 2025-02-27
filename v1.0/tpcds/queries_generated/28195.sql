
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        INITCAP(ca_city) AS formatted_city,
        UPPER(ca_state) AS state,
        SUBSTRING(ca_zip FROM 1 FOR 5) AS zip_prefix,
        ca_country
    FROM 
        customer_address
    WHERE 
        ca_country LIKE '%United States%' 
), customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        pa.full_address,
        pa.formatted_city,
        pa.state,
        pa.zip_prefix
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        processed_addresses pa ON c.c_current_addr_sk = pa.ca_address_sk
), purchase_statistics AS (
    SELECT 
        ci.customer_name,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_net_paid) AS avg_spent
    FROM 
        web_sales ws
    JOIN 
        customer_info ci ON ci.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ci.customer_name
)
SELECT 
    ci.customer_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.total_orders,
    ci.total_profit,
    ci.avg_spent,
    ci.formatted_city,
    (SELECT COUNT(*) FROM customer_info) AS customer_count
FROM 
    purchase_statistics ci
ORDER BY 
    ci.total_profit DESC
LIMIT 10;
