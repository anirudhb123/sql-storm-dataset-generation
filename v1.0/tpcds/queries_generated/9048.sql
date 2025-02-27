
WITH Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        a.ca_city,
        a.ca_state,
        a.ca_country
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS a ON c.c_current_addr_sk = a.ca_address_sk
),
Sales_Info AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales AS ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
Combined_Info AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        si.total_profit,
        si.total_quantity,
        si.total_orders
    FROM 
        Customer_Info AS ci
    LEFT JOIN 
        Sales_Info AS si ON ci.c_customer_sk = si.ws_bill_customer_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    COALESCE(si.total_profit, 0) AS total_profit,
    COALESCE(si.total_quantity, 0) AS total_quantity,
    COALESCE(si.total_orders, 0) AS total_orders,
    RANK() OVER (ORDER BY COALESCE(si.total_profit, 0) DESC) AS profit_rank
FROM 
    Combined_Info AS ci
ORDER BY 
    profit_rank
LIMIT 10;
