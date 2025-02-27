
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 1 AS hierarchy_level
    FROM customer_address
    WHERE ca_city IS NOT NULL AND ca_state IS NOT NULL
    UNION ALL
    SELECT a.ca_address_sk, a.ca_city, a.ca_state, a.ca_country, ah.hierarchy_level + 1
    FROM customer_address a
    JOIN AddressHierarchy ah ON a.ca_state = ah.ca_state AND a.ca_city = ah.ca_city
    WHERE ah.hierarchy_level < 5
), 
CustomerPurchases AS (
    SELECT c.c_customer_sk, COUNT(DISTINCT ws_order_number) AS total_orders,
           SUM(ws_net_paid) AS total_spent, 
           SUM(ws_net_paid_inc_tax) AS total_spent_tax_inclusive
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
), 
PromotionalSales AS (
    SELECT p.p_promo_sk, COUNT(DISTINCT ws_order_number) AS promo_order_count
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY p.p_promo_sk
), 
ItemSales AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_quantity, 
           AVG(ws.ws_sales_price) AS avg_price, 
           ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS rnk
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
)
SELECT a.ca_city, 
       a.ca_state, 
       COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
       COALESCE(SUM(cp.total_spent), 0) AS total_spent_by_customers,
       COALESCE(MAX(ps.promo_order_count), 0) AS max_orders_with_promotions,
       STRING_AGG(DISTINCT i.total_quantity::TEXT || ' items with avg price ' || i.avg_price::TEXT, ', ') AS item_sales_info
FROM AddressHierarchy a
LEFT JOIN CustomerPurchases cp ON a.ca_city = (SELECT ca_city FROM customer_address WHERE ca_address_sk = c.c_current_addr_sk LIMIT 1)
LEFT JOIN Customer c ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN PromotionalSales ps ON ps.promo_order_count > 
                                  (SELECT AVG(promo_order_count) FROM PromotionalSales WHERE promo_order_count IS NOT NULL)
LEFT JOIN ItemSales i ON i.rnk <= 3
WHERE a.ca_country = 'USA' AND (a.ca_state IS NOT NULL OR a.ca_city IS NOT NULL)
GROUP BY a.ca_city, a.ca_state
HAVING COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY total_spent_by_customers DESC, max_orders_with_promotions ASC;
