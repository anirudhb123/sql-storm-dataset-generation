
WITH RECURSIVE sales_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, NULL AS parent_id, 0 AS depth
    FROM customer c
    WHERE c.c_customer_sk IN (SELECT DISTINCT ss_customer_sk FROM store_sales)
    UNION ALL
    SELECT s.c_customer_sk, s.c_first_name, s.c_last_name, sh.c_customer_sk AS parent_id, sh.depth + 1
    FROM sales_hierarchy sh
    JOIN customer s ON sh.c_customer_sk = s.c_current_hdemo_sk
),
monthly_sales AS (
    SELECT d.d_year, d.d_month_seq, SUM(ss.ss_net_paid_inc_tax) AS total_sales
    FROM date_dim d
    JOIN store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY d.d_year, d.d_month_seq
),
promotions AS (
    SELECT p.p_promo_id, p.p_promo_name, COUNT(DISTINCT ws.ws_order_number) AS promo_sales_count
    FROM promotion p
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_id, p.p_promo_name
)
SELECT 
    concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_tickets,
    SUM(ss.ss_net_paid_inc_tax) AS total_amount_paid,
    mh.d_year,
    mh.d_month_seq,
    COALESCE(p.promo_sales_count, 0) AS promotion_sales_count,
    RANK() OVER (PARTITION BY mh.d_year, mh.d_month_seq ORDER BY SUM(ss.ss_net_paid_inc_tax) DESC) AS sales_rank
FROM customer c
LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN sales_hierarchy sh ON sh.c_customer_sk = c.c_customer_sk
JOIN monthly_sales mh ON mh.d_year = YEAR(CURRENT_DATE) AND mh.d_month_seq = MONTH(CURRENT_DATE)
LEFT JOIN promotions p ON p.promo_sales_count > 0
WHERE c.c_birth_year IS NOT NULL
AND c.c_current_addr_sk IS NOT NULL
GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, mh.d_year, mh.d_month_seq, p.promo_sales_count
HAVING total_amount_paid > 1000
ORDER BY total_amount_paid DESC, customer_name;
