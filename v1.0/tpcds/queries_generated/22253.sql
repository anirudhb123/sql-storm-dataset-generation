
WITH RECURSIVE promo_dates AS (
    SELECT p_promo_sk, p_start_date_sk, p_end_date_sk, 
           ROW_NUMBER() OVER (PARTITION BY p_promo_sk ORDER BY p_start_date_sk) AS rn
    FROM promotion
    WHERE p_discount_active = 'Y'
),
customer_orders AS (
    SELECT c.c_customer_sk, 
           SUM(COALESCE(ws.ws_net_profit, 0) + COALESCE(cs.cs_net_profit, 0)) AS total_net_profit
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    GROUP BY c.c_customer_sk
), 
ranked_customers AS (
    SELECT c.*, RANK() OVER (ORDER BY co.total_net_profit DESC) AS rank
    FROM customer_orders co
    JOIN customer c ON co.c_customer_sk = c.c_customer_sk
)
SELECT
    r.first_name,
    r.last_name,
    COUNT(DISTINCT a.ca_address_sk) AS unique_addresses,
    SUM(CASE 
        WHEN r.rank <= 10 THEN 1 
        ELSE 0 
    END) AS top_10_flag,
    AVG(CASE 
        WHEN r.rank BETWEEN 11 AND 20 THEN co.total_net_profit 
        ELSE NULL 
    END) AS avg_profit_top_20,
    STRING_AGG(DISTINCT CONCAT(a.ca_city, ', ', a.ca_state, ' ', a.ca_zip)) AS address_summary
FROM ranked_customers r
LEFT JOIN customer_address a ON r.c_current_addr_sk = a.ca_address_sk
WHERE a.ca_country IS NOT NULL
GROUP BY r.first_name, r.last_name
HAVING COUNT(DISTINCT a.ca_address_sk) > 1 AND 
       SUM(COALESCE(co.total_net_profit * 
                     (CASE 
                         WHEN r.rank BETWEEN 1 AND 10 THEN 1.2 
                         ELSE 0.8 
                     END), 
                     0)) > 1000
ORDER BY unique_addresses DESC, r.last_name ASC
OFFSET 5 ROWS FETCH NEXT 15 ROWS ONLY;
