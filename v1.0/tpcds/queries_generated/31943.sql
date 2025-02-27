
WITH RECURSIVE income_hist AS (
    SELECT 
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.dep_count,
        hd.vehicle_count,
        ROW_NUMBER() OVER (PARTITION BY hd.hd_income_band_sk ORDER BY hd.dep_count DESC) as rank
    FROM 
        household_demographics hd
    WHERE 
        hd.hd_income_band_sk IS NOT NULL
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(ca.ca_city, 'Unknown') AS city,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, ca.ca_city
),
order_summary AS (
    SELECT 
        ci.c_customer_sk,
        ci.city,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_paid_inc_tax) AS avg_spent
    FROM 
        customer_info ci
    JOIN 
        web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ci.c_customer_sk, ci.city
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.city,
    oi.total_profit,
    oi.avg_spent,
    ih.hd_buy_potential
FROM 
    customer_info ci
JOIN 
    order_summary oi ON ci.c_customer_sk = oi.c_customer_sk
LEFT JOIN 
    income_hist ih ON ci.city = (SELECT ca.ca_city FROM customer_address ca WHERE ca.ca_address_sk = c.c_current_addr_sk LIMIT 1)
WHERE 
    oi.total_profit > (SELECT AVG(oi2.total_profit) FROM order_summary oi2)
ORDER BY 
    oi.total_profit DESC
LIMIT 10;

