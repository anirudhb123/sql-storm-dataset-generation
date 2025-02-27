
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales AS ws
    LEFT JOIN 
        customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        ws.web_site_sk
    HAVING 
        SUM(ws.ws_net_profit) > 0
),
address_data AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COALESCE(c.c_first_name, 'Unknown') AS first_name,
        COALESCE(c.c_last_name, 'Unknown') AS last_name
    FROM 
        customer_address AS ca
    LEFT JOIN 
        customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
),
promotion_data AS (
    SELECT 
        p.p_promo_id,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost ELSE 0 END) AS active_discount,
        COUNT(DISTINCT p.p_item_sk) AS item_count
    FROM 
        promotion AS p
    WHERE 
        p.p_start_date_sk < (SELECT MAX(d.d_date_sk) FROM date_dim AS d WHERE d.d_date = CURRENT_DATE)
    GROUP BY 
        p.p_promo_id
)
SELECT 
    ad.ca_city, 
    ad.ca_state,
    ps.p_promo_id,
    ps.active_discount,
    ps.item_count,
    rs.total_orders,
    rs.total_profit
FROM 
    address_data AS ad
JOIN 
    promotion_data AS ps ON ps.item_count > 0
LEFT JOIN 
    ranked_sales AS rs ON ad.ca_address_sk = rs.web_site_sk
WHERE 
    ad.ca_state IN ('CA', 'NY')
    AND rs.profit_rank <= 10
ORDER BY 
    rs.total_profit DESC NULLS LAST
FETCH FIRST 50 ROWS ONLY;
