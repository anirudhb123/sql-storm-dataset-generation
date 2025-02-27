
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS join_date,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
Promotions AS (
    SELECT 
        p.p_promo_id,
        p.p_promo_name,
        p.p_discount_active,
        COUNT(*) AS promo_usage_count
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id, p.p_promo_name, p.p_discount_active
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ws.ws_sold_date_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        web_sales ws
    JOIN 
        customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number, ws.ws_sold_date_sk, ca.ca_city, ca.ca_state, ca.ca_country
)
SELECT 
    ci.full_name,
    ci.join_date,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    p.promo_name,
    p.promo_usage_count,
    sd.total_quantity,
    sd.total_profit
FROM 
    CustomerInfo ci
LEFT JOIN 
    Promotions p ON ci.c_customer_id = p.p_promo_id
LEFT JOIN 
    SalesData sd ON ci.c_customer_id = sd.ws_order_number
WHERE 
    ci.cd_gender = 'M'
    AND ci.cd_marital_status = 'M'
    AND sd.total_quantity > 0
ORDER BY 
    sd.total_profit DESC, 
    ci.full_name;
