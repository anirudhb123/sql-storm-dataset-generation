
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CA.ca_city,
        CA.ca_state,
        CD.cd_gender,
        CD.cd_marital_status,
        CD.cd_education_status,
        CD.cd_purchase_estimate,
        (CASE 
            WHEN CD.cd_credit_rating = 'High' THEN 'Excellent'
            WHEN CD.cd_credit_rating = 'Medium' THEN 'Good'
            ELSE 'Average'
        END) AS credit_rating_category
    FROM 
        customer c
    JOIN 
        customer_demographics CD ON c.c_current_cdemo_sk = CD.cd_demo_sk
    JOIN 
        customer_address CA ON c.c_current_addr_sk = CA.ca_address_sk
),
date_info AS (
    SELECT 
        d.d_date_id,
        d.d_day_name,
        d.d_month_seq,
        d.d_year
    FROM 
        date_dim d
    WHERE 
        d.d_year IN (2022, 2023)
),
sales_info AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_web_site_sk
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        w.web_mkt_id IS NOT NULL
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.cd_gender,
    di.d_day_name,
    SUM(si.ws_net_profit) AS total_net_profit,
    COUNT(si.ws_order_number) AS total_orders,
    SUM(si.ws_quantity) AS total_quantity
FROM 
    customer_info ci
JOIN 
    sales_info si ON ci.c_customer_id = si.ws_bill_customer_sk
JOIN 
    date_info di ON si.ws_sold_date_sk = di.d_date_id
GROUP BY 
    ci.full_name, ci.ca_city, ci.ca_state, ci.cd_gender, di.d_day_name
HAVING 
    SUM(si.ws_net_profit) > 1000
ORDER BY 
    total_net_profit DESC;
