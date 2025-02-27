
WITH address_info AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LOWER(ca_city) AS lower_city,
        UPPER(ca_state) AS upper_state,
        REPLACE(ca_zip, '-', '') AS zip_code_clean
    FROM 
        customer_address
),
customer_info AS (
    SELECT
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_info AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.net_profit) AS total_profit,
        COUNT(ws.order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.bill_customer_sk
),
final_report AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ai.full_address,
        ai.lower_city,
        ai.upper_state,
        ai.zip_code_clean,
        COALESCE(si.total_profit, 0) AS total_profit,
        COALESCE(si.total_orders, 0) AS total_orders
    FROM 
        customer_info ci
    JOIN 
        address_info ai ON ci.c_customer_sk = ai.ca_address_sk
    LEFT JOIN 
        sales_info si ON ci.c_customer_sk = si.bill_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    full_address,
    lower_city,
    upper_state,
    zip_code_clean,
    total_profit,
    total_orders
FROM 
    final_report
WHERE 
    total_profit > 1000
ORDER BY 
    total_orders DESC, total_profit DESC
LIMIT 100;
