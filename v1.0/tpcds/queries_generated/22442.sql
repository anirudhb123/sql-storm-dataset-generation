
WITH RECURSIVE address_totals AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        COUNT(c_customer_sk) AS total_customers,
        SUM(COALESCE(c_birth_year, 0)) AS total_birth_years
    FROM 
        customer_address a
    LEFT JOIN 
        customer c ON a.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca_address_sk, ca_city, ca_state
),
average_income AS (
    SELECT 
        hd.hd_income_band_sk,
        AVG(CASE 
            WHEN ib.ib_lower_bound IS NULL THEN 0 
            ELSE ib.ib_lower_bound 
        END) AS avg_lower_bound,
        AVG(COALESCE(ib.ib_upper_bound, 100000)) AS avg_upper_bound
    FROM 
        household_demographics hd
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        hd.hd_income_band_sk
),
promotions AS (
    SELECT 
        p.p_promo_id,
        p.p_promo_name,
        COUNT(DISTINCT ws.ws_order_number) AS promotions_used,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk 
    GROUP BY 
        p.p_promo_id, p.p_promo_name
),
customer_analytics AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    GROUP BY 
        c.c_customer_id
)

SELECT 
    at.ca_city,
    at.ca_state,
    at.total_customers,
    at.total_birth_years,
    ai.avg_lower_bound,
    ai.avg_upper_bound,
    p.promo_name,
    p.promotions_used,
    p.total_profit,
    ca.c_customer_id,
    ca.net_profit,
    ca.total_orders,
    ca.profit_rank
FROM 
    address_totals at
JOIN 
    average_income ai ON at.total_birth_years > ai.avg_lower_bound
LEFT JOIN 
    promotions p ON at.total_customers = p.promotions_used
JOIN 
    customer_analytics ca ON ca.net_profit > 0
WHERE 
    (at.ca_state IS NOT NULL OR at.ca_city IS NOT NULL)
    AND (p.promotions_used IS NOT NULL OR ca.total_orders IS NOT NULL)
ORDER BY 
    at.ca_state ASC, 
    at.total_customers DESC, 
    ca.net_profit DESC;
