
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           1 AS level
    FROM customer c
    WHERE c.c_birth_year IS NULL OR c.c_birth_year > 1980
    UNION ALL
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ch.c_current_cdemo_sk,
           ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
    WHERE ch.level < 3
),
sales_data AS (
    SELECT ws.ws_sales_price, 
           SUM(ws.ws_quantity) AS total_quantity_sold,
           COUNT(DISTINCT ws.ws_order_number) AS number_of_orders,
           CASE 
               WHEN ws.ws_sales_price > 100 THEN 'expensive'
               WHEN ws.ws_sales_price BETWEEN 50 AND 100 THEN 'average'
               ELSE 'cheap'
           END AS price_category
    FROM web_sales ws
    GROUP BY ws.ws_sales_price
),
ranked_sales AS (
    SELECT sd.*, 
           RANK() OVER (PARTITION BY sd.price_category ORDER BY sd.total_quantity_sold DESC) AS sales_rank
    FROM sales_data sd
),
customer_promo AS (
    SELECT cd.cd_demo_sk,
           COUNT(p.p_promo_sk) AS promotion_count,
           RANK() OVER (ORDER BY COUNT(p.p_promo_sk) DESC) AS promo_rank
    FROM customer_demographics cd
    LEFT JOIN promotion p ON cd.cd_demo_sk = p.p_response_target
    GROUP BY cd.cd_demo_sk
)
SELECT 
    ah.c_first_name || ' ' || ah.c_last_name AS customer_name,
    COALESCE(SUM(rws.total_quantity_sold), 0) AS total_quantity,
    COALESCE(cp.promotion_count, 0) AS promotions_received,
    rs.price_category,
    rs.sales_rank
FROM customer_hierarchy ah
LEFT JOIN ranked_sales rs ON ah.c_current_cdemo_sk = rs.ws_sales_price
LEFT JOIN customer_promo cp ON ah.c_current_cdemo_sk = cp.cd_demo_sk
LEFT JOIN web_sales ws ON ah.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY ah.c_first_name, ah.c_last_name, rs.price_category, rs.sales_rank, cp.promotion_count
HAVING SUM(COALESCE(ws.ws_quantity, 0)) > 5 OR (cp.promotion_count > 2 AND rs.sales_rank <= 3)
ORDER BY total_quantity DESC, customer_name
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
