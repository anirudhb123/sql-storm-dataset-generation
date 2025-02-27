
WITH customer_info AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
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
sales_info AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_profit) AS total_net_profit, 
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
final_report AS (
    SELECT 
        ci.c_customer_id,
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        si.total_net_profit,
        si.total_orders,
        ci.full_address,
        CASE 
            WHEN si.total_net_profit > 1000 THEN 'High Value Customer'
            WHEN si.total_net_profit > 500 THEN 'Medium Value Customer'
            ELSE 'Low Value Customer'
        END AS customer_value_category
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_info si ON ci.c_customer_id = si.ws_bill_customer_sk
)
SELECT 
    customer_value_category, 
    COUNT(*) AS customer_count
FROM 
    final_report
GROUP BY 
    customer_value_category
ORDER BY 
    customer_count DESC;
