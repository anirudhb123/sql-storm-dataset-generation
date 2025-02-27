
WITH AddressDetails AS (
    SELECT 
        ca.ca_country,
        ca.ca_state,
        ca.ca_city,
        ca.ca_zip,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        STRING_AGG(CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_country, ca.ca_state, ca.ca_city, ca.ca_zip
), PromotionStats AS (
    SELECT 
        p.p_promo_id,
        p.p_promo_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count,
        STRING_AGG(DISTINCT CONCAT('Promotion: ', p.p_promo_name, ' - Profit: $', ROUND(SUM(ws.ws_net_profit), 2)), '; ') AS promo_summary
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id, p.p_promo_name
)
SELECT 
    ad.ca_country,
    ad.ca_state,
    ad.ca_city,
    ad.ca_zip,
    ad.customer_count,
    ad.customer_names,
    ps.total_profit,
    ps.order_count,
    ps.promo_summary
FROM 
    AddressDetails ad
LEFT JOIN 
    PromotionStats ps ON ps.total_profit > 10000
ORDER BY 
    ad.ca_country, ad.ca_state, ad.ca_city;
