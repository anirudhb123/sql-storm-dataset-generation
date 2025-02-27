
WITH AddressParts AS (
    SELECT
        ca_address_sk,
        TRIM(COALESCE(ca_street_number, '')) || ' ' || 
        TRIM(COALESCE(ca_street_name, '')) || ' ' || 
        TRIM(COALESCE(ca_street_type, '')) AS full_address,
        TRIM(COALESCE(ca_city, '')) || ', ' || 
        TRIM(COALESCE(ca_state, '')) || ' ' || 
        TRIM(COALESCE(ca_zip, '')) AS city_state_zip
    FROM
        customer_address
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        a.full_address,
        a.city_state_zip
    FROM
        customer c
    JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN AddressParts a ON c.c_current_addr_sk = a.ca_address_sk
),
PromotionalData AS (
    SELECT
        p.promo_name,
        p.p_start_date_sk,
        p.p_end_date_sk,
        count(p.p_promo_sk) AS promo_count
    FROM 
        promotion p
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY
        p.promo_name, p.p_start_date_sk, p.p_end_date_sk
)
SELECT
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.city_state_zip,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_profit) AS total_profit,
    pd.promo_name,
    pd.promo_count
FROM 
    CustomerInfo ci
LEFT JOIN web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
JOIN PromotionalData pd ON ws.ws_promo_sk = pd.p_promo_sk
GROUP BY 
    ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.city_state_zip, pd.promo_name, pd.promo_count
ORDER BY 
    total_profit DESC, ci.c_last_name, ci.c_first_name;
