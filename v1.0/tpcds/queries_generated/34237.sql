
WITH RECURSIVE income_hierarchy AS (
    SELECT hd_demo_sk, ib_income_band_sk, 1 AS level
    FROM household_demographics
    JOIN income_band ON household_demographics.hd_income_band_sk = income_band.ib_income_band_sk
    WHERE ib_lower_bound >= 50000
    UNION ALL
    SELECT h.hd_demo_sk, h.ib_income_band_sk, ih.level + 1
    FROM income_hierarchy ih
    JOIN household_demographics h ON h.hd_income_band_sk = (
        SELECT ib_income_band_sk
        FROM income_band
        WHERE ib_lower_bound < (
            SELECT MAX(ib_upper_bound)
            FROM income_band
            WHERE ib_income_band_sk = ih.ib_income_band_sk
        )
        ORDER BY ib_income_band_sk DESC
        LIMIT 1
    )
    WHERE ih.level < 5
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    MAX(ws.ws_sales_price) AS max_sales_price,
    MIN(ws.ws_sales_price) AS min_sales_price,
    STRING_AGG(DISTINCT p.p_promo_name, ', ') AS promo_names
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN 
    income_hierarchy ih ON ih.hd_demo_sk = c.c_current_hdemo_sk
WHERE 
    (c.c_birth_year BETWEEN 1980 AND 1990) 
    AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
    AND (ca.ca_city IS NOT NULL OR ca.ca_state = 'CA')
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city
HAVING 
    SUM(ws.ws_net_profit) > 1000
ORDER BY 
    total_net_profit DESC
LIMIT 100;
