
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        ca.ca_city, 
        ca.ca_state, 
        cd.cd_gender,
        ARRAY_AGG(DISTINCT ca.ca_street_name || ' ' || ca.ca_street_number || ', ' || ca.ca_zip) AS full_address,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, cd.cd_gender
),
Promotions AS (
    SELECT 
        p.p_promo_id, 
        p.p_promo_name, 
        p.p_start_date_sk, 
        p.p_end_date_sk,
        COUNT(DISTINCT ws.ws_order_number) AS promotion_usage
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id, p.p_promo_name, p.p_start_date_sk, p.p_end_date_sk
),
FinalBenchmark AS (
    SELECT 
        ci.c_customer_id,
        ci.c_first_name || ' ' || ci.c_last_name AS full_name,
        ci.ca_city || ', ' || ci.ca_state AS location,
        ci.cd_gender,
        ci.total_orders,
        STRING_AGG(p.p_promo_name || ' used ' || p.promotion_usage || ' times', '; ') AS promotions
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        Promotions p ON ci.total_orders > 0
    GROUP BY 
        ci.c_customer_id, ci.c_first_name, ci.c_last_name, ci.ca_city, ci.ca_state, ci.cd_gender, ci.total_orders
)
SELECT * 
FROM FinalBenchmark
ORDER BY total_orders DESC, full_name;
