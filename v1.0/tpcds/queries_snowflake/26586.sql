
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(COALESCE(c.c_salutation, ''), ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_info AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        COUNT(*) AS address_count
    FROM 
        customer_address ca
    GROUP BY 
        ca.ca_city, ca.ca_state
),
sales_info AS (
    SELECT 
        ws.ws_ship_date_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_date_sk
),
gender_distribution AS (
    SELECT 
        cd.cd_gender,
        COUNT(c.c_customer_sk) AS gender_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
final_report AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        sd.total_orders,
        sd.total_profit,
        (SELECT COUNT(*) FROM address_info ai WHERE ai.ca_city = ci.ca_city AND ai.ca_state = ci.ca_state) AS city_address_count,
        gd.gender_count
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_info sd ON sd.ws_ship_date_sk = (SELECT MAX(w.ws_sold_date_sk) FROM web_sales w WHERE w.ws_ship_customer_sk = ci.c_customer_sk)
    LEFT JOIN 
        gender_distribution gd ON gd.cd_gender = ci.cd_gender
)

SELECT 
    full_name,
    ca_city,
    ca_state,
    total_orders,
    total_profit,
    city_address_count,
    gender_count
FROM
    final_report
WHERE 
    total_orders > 0
ORDER BY 
    total_profit DESC, city_address_count DESC
LIMIT 100;
