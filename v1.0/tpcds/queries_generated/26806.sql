
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
dates_info AS (
    SELECT 
        d.d_date_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq
    FROM 
        date_dim d
    WHERE 
        d.d_year = 2023
),
sales_info AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        dates_info d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.ws_item_sk
),
promotions_info AS (
    SELECT 
        p.p_promo_id,
        p.p_promo_name,
        COUNT(*) AS promo_count
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id, p.p_promo_name
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.cd_purchase_estimate,
    ci.ca_city,
    ci.ca_state,
    si.total_quantity,
    si.total_profit,
    pi.promo_count
FROM 
    customer_info ci
JOIN 
    sales_info si ON ci.c_customer_sk = si.ws_item_sk
LEFT JOIN 
    promotions_info pi ON si.ws_item_sk = pi.p_promo_id
WHERE 
    ci.cd_gender = 'F'
ORDER BY 
    si.total_profit DESC
LIMIT 100;
