
WITH CONCATENATED_INFO AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type AS full_address,
        d.d_date AS purchase_date,
        d.d_month_seq AS purchase_month,
        sm.sm_type AS shipping_method,
        LISTAGG(DISTINCT p.p_promo_name, ', ') WITHIN GROUP (ORDER BY p.p_promo_name) AS promotions_used
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, d.d_date, d.d_month_seq, sm.sm_type
)
SELECT 
    full_name,
    full_address,
    purchase_date,
    purchase_month,
    shipping_method,
    COALESCE(promotions_used, 'None') AS promotions_used
FROM 
    CONCATENATED_INFO
WHERE 
    purchase_month IN (SELECT DISTINCT d_month_seq FROM date_dim WHERE d_year = 2023)
ORDER BY 
    purchase_date DESC
LIMIT 100;
