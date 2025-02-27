
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk, 
           0 AS level
    FROM customer
    WHERE c_current_addr_sk IS NOT NULL
    UNION ALL
    SELECT c.customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, 
           h.level + 1
    FROM customer c
    JOIN CustomerHierarchy h ON c.c_current_addr_sk = h.c_current_addr_sk
), AddressSummary AS (
    SELECT ca_state, COUNT(*) AS address_count, 
           COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca_state
), SalesData AS (
    SELECT d.d_year, 
           SUM(ws.ws_ext_sales_price) AS total_sales,
           AVG(ws.ws_net_profit) AS avg_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
), PromotionSummary AS (
    SELECT p.p_promo_id, 
           SUM(cs.cs_quantity) AS total_quantity
    FROM promotion p
    JOIN catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    GROUP BY p.p_promo_id
)
SELECT a.ca_state, 
       a.address_count, 
       a.customer_count,
       COALESCE(s.total_sales, 0) AS web_sales,
       COALESCE(s.avg_net_profit, 0) AS avg_profit,
       p.p_promo_id, 
       p.total_quantity
FROM AddressSummary a
LEFT JOIN SalesData s ON a.customer_count > 100
LEFT JOIN PromotionSummary p ON p.total_quantity > 50
WHERE a.address_count > 10
ORDER BY a.ca_state, p.total_quantity DESC
LIMIT 10;
