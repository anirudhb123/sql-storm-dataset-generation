
WITH RECURSIVE ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_item_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_paid DESC) AS sales_rank,
        COALESCE(NULLIF(ws.ws_ship_date_sk, 0), ws.ws_sold_date_sk) AS effective_ship_date,
        ws.ws_net_paid
    FROM web_sales ws
    WHERE ws.ws_net_paid > 0
),
cumulative_sales AS (
    SELECT 
        r.web_site_sk,
        r.ws_order_number,
        SUM(r.ws_net_paid) OVER (PARTITION BY r.web_site_sk ORDER BY r.sales_rank) AS cum_sales,
        r.effective_ship_date,
        ROW_NUMBER() OVER (PARTITION BY r.web_site_sk ORDER BY r.effective_ship_date ASC) AS date_rank
    FROM ranked_sales r
)
SELECT 
    r.ca_country,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    SUM(CASE 
            WHEN d.d_holiday = 'Y' THEN cs.cum_sales 
            ELSE 0 
        END) AS holiday_sales,
    MAX(CASE 
            WHEN c.c_birth_year IS NULL THEN 'N/A' 
            ELSE EXTRACT(YEAR FROM CURRENT_DATE) - c.c_birth_year 
        END) AS avg_customer_age,
    STRING_AGG(DISTINCT d.d_day_name ORDER BY d.d_date) AS sale_days
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN cumulative_sales cs ON cs.ws_order_number = c.c_first_sales_date_sk
JOIN date_dim d ON d.d_date_sk = cs.effective_ship_date
LEFT JOIN promotion p ON p.p_item_sk = cs.ws_item_sk AND p.p_discount_active = 'Y'
WHERE 
    ca.ca_country IS NOT NULL AND 
    ca.ca_state NOT IN ('XX', 'YY') AND 
    (c.c_preferred_cust_flag = 'Y' OR c.c_first_shipto_date_sk IS NULL)
GROUP BY ca.ca_country
HAVING COUNT(DISTINCT c.c_customer_sk) > 0
ORDER BY total_customers DESC
LIMIT 10;
