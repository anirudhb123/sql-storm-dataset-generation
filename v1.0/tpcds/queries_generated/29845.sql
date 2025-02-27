
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        c.c_email_address,
        CASE 
            WHEN cd.cd_buy_potential IS NOT NULL THEN 
                CASE
                    WHEN cd.cd_buy_potential LIKE '%high%' THEN 'High Potential Customer'
                    WHEN cd.cd_buy_potential LIKE '%medium%' THEN 'Medium Potential Customer'
                    ELSE 'Low Potential Customer'
                END 
            ELSE 'Unknown Potential'
        END AS potential_category
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_info AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
final_report AS (
    SELECT 
        ci.full_name,
        ci.c_email_address,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        si.total_net_profit,
        si.orders_count,
        ci.potential_category
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_info si ON ci.c_customer_id = si.ws_bill_customer_sk
)
SELECT 
    full_name,
    c_email_address,
    ca_city,
    ca_state,
    ca_country,
    COALESCE(total_net_profit, 0) AS total_net_profit,
    COALESCE(orders_count, 0) AS orders_count,
    potential_category
FROM 
    final_report
WHERE 
    COALESCE(total_net_profit, 0) > 1000
ORDER BY 
    total_net_profit DESC, orders_count DESC;
