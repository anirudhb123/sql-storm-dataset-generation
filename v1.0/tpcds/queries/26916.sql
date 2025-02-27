
WITH CustomerCity AS (
    SELECT ca_city, 
           COUNT(DISTINCT c_customer_sk) AS customer_count,
           STRING_AGG(DISTINCT CONCAT(c_first_name, ' ', c_last_name), '; ') AS customer_names
    FROM customer_address a 
    JOIN customer c ON a.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca_city
),
PromotedItems AS (
    SELECT p.p_promo_id,
           p.p_promo_name,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders,
           SUM(ws.ws_ext_sales_price) AS total_sales
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_id, p.p_promo_name
),
TopCities AS (
    SELECT ca_city,
           customer_count, 
           customer_names, 
           ROW_NUMBER() OVER (ORDER BY customer_count DESC) AS city_rank
    FROM CustomerCity
),
TopPromotions AS (
    SELECT p.p_promo_id, 
           p.p_promo_name, 
           total_orders,
           total_sales, 
           ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS promo_rank
    FROM PromotedItems p
)
SELECT t.city_rank, 
       t.ca_city, 
       t.customer_count, 
       t.customer_names, 
       p.promo_rank, 
       p.p_promo_name, 
       p.total_orders, 
       p.total_sales
FROM TopCities t
JOIN TopPromotions p ON t.city_rank = p.promo_rank
WHERE t.city_rank <= 10 AND p.promo_rank <= 10;
