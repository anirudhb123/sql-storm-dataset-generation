
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS customer_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 30 FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_bill_customer_sk
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year, c.c_birth_month, c.c_birth_day) AS rn
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    ci.c_customer_id,
    ci.ca_city,
    ci.ca_state,
    rs.total_profit,
    rs.total_orders
FROM 
    ranked_sales rs
JOIN 
    customer_info ci ON rs.ws_bill_customer_sk = ci.c_customer_sk
WHERE 
    rs.customer_rank = 1
    AND ci.rn = 1
    AND ci.cd_gender = 'F'
    AND EXISTS (
        SELECT 1 
        FROM store_sales ss 
        WHERE ss.ss_customer_sk = rs.ws_bill_customer_sk
          AND ss.ss_net_paid > 500
    )
ORDER BY 
    rs.total_profit DESC
LIMIT 10;
