
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rnk,
        SUM(ws.ws_net_profit) OVER (PARTITION BY ws.web_site_sk) AS total_net_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) 
        AND (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
best_websites AS (
    SELECT 
        r.web_site_sk,
        r.ws_order_number,
        r.ws_net_profit,
        r.total_net_profit
    FROM 
        ranked_sales r
    WHERE 
        r.rnk <= 3
),
customer_info AS (
    SELECT 
        DISTINCT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        CA.ca_country,
        COALESCE(ALL(c.c_birth_month), 0) AS month_birth
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address CA ON c.c_current_addr_sk = CA.ca_address_sk
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.ca_country,
    (SELECT COUNT(*) FROM best_websites bw WHERE bw.web_site_sk IN (
        SELECT ws.web_site_sk 
        FROM web_sales ws 
        WHERE ws.ws_bill_customer_sk = ci.c_customer_id
    )) AS num_of_high_profit_orders,
    CASE 
        WHEN ci.month_birth IS NULL THEN 'Unknown'
        ELSE CASE 
            WHEN ci.month_birth BETWEEN 1 AND 6 THEN 'First Half'
            ELSE 'Second Half'
        END
    END AS birth_half
FROM 
    customer_info ci
LEFT JOIN 
    best_websites bw ON bw.ws_order_number = (SELECT MAX(ws_order_number) FROM web_sales WHERE ws_bill_customer_sk = ci.c_customer_id)
WHERE 
    ci.ca_country IS NOT NULL
ORDER BY 
    num_of_high_profit_orders DESC, ci.c_customer_id;
