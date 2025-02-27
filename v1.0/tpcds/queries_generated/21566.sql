
WITH RECURSIVE date_range AS (
    SELECT MIN(d_date) AS start_date, MAX(d_date) AS end_date
    FROM date_dim
),
customer_stats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        COALESCE(cd.cd_dep_count, 0) AS dependent_count,
        SUM(CASE WHEN cs.net_profit IS NOT NULL THEN cs.net_profit ELSE 0 END) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ss.ss_ticket_number) FILTER (WHERE ss.ss_sales_price > 50) AS high_value_orders
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE c.c_birth_day BETWEEN 1 AND 15 
        AND c.c_birth_month = EXTRACT(MONTH FROM CURRENT_DATE)
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_dep_count
),
item_with_promotions AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc, 
        p.p_promo_name,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY p.p_start_date_sk) AS promo_order
    FROM item i
    LEFT JOIN promotion p ON i.i_item_sk = p.p_item_sk
    WHERE p.p_discount_active = 'Y'
    ORDER BY i.i_item_id
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT cs.c_customer_id) AS active_customers,
    SUM(CASE WHEN cs.total_net_profit IS NOT NULL THEN cs.total_net_profit ELSE 0 END) AS city_net_profit,
    AVG(cs.dependent_count) AS average_dependents,
    STRING_AGG(DISTINCT p.promo_name) AS promotions_in_city
FROM customer_address ca
JOIN customer_stats cs ON ca.ca_address_sk = cs.customer_id
LEFT JOIN item_with_promotions p ON p.i_item_id IN (SELECT i.i_item_id FROM item i WHERE i.i_current_price > 15)
WHERE ca.ca_state = 'CA' 
    AND ca.ca_country IS NOT NULL
GROUP BY ca.ca_city
HAVING COUNT(cs.c_customer_id) > 5
ORDER BY city_net_profit DESC
LIMIT 10
OFFSET 5;
