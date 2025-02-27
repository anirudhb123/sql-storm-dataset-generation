
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_street_number, ca_street_name, ca_city, ca_state, 1 AS level
    FROM customer_address
    WHERE ca_city IS NOT NULL

    UNION ALL

    SELECT a.ca_address_sk, a.ca_street_number, a.ca_street_name, a.ca_city, a.ca_state, ah.level + 1
    FROM customer_address a
    JOIN AddressHierarchy ah ON a.ca_city = ah.ca_city AND a.ca_state = ah.ca_state
    WHERE a.ca_address_sk != ah.ca_address_sk
),
CustomerPromotions AS (
    SELECT c.c_customer_sk, COUNT(DISTINCT p.p_promo_sk) AS promo_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY c.c_customer_sk
),
TopPromotedCustomers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cp.promo_count
    FROM customer c
    JOIN CustomerPromotions cp ON c.c_customer_sk = cp.c_customer_sk
    WHERE cp.promo_count > (SELECT AVG(promo_count) FROM CustomerPromotions)
)
SELECT ah.ca_city, ah.ca_state, COUNT(DISTINCT c.c_customer_id) AS unique_customers,
       SUM(CASE WHEN t.promo_count IS NOT NULL THEN 1 ELSE 0 END) AS promoted_customers_count,
       AVG(ws.ws_net_profit) AS avg_net_profit
FROM customer_address ca
LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN TopPromotedCustomers t ON c.c_customer_sk = t.c_customer_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN AddressHierarchy ah ON ca.ca_city = ah.ca_city AND ca.ca_state = ah.ca_state
GROUP BY ah.ca_city, ah.ca_state
HAVING COUNT(DISTINCT c.c_customer_id) > 0
ORDER BY avg_net_profit DESC
LIMIT 10;
