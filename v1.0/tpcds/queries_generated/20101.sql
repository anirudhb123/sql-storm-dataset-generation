
WITH ranked_sales AS (
    SELECT 
        s.s_store_sk,
        s.ss_ticket_number,
        SUM(COALESCE(ss.ss_ext_sales_price, 0)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
    FROM store_sales s
    LEFT JOIN item i ON s.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON s.ss_promo_sk = p.p_promo_sk 
    WHERE i.i_current_price IS NOT NULL 
    GROUP BY s.s_store_sk, s.ss_ticket_number
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid) AS total_net_paid
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE ss.ss_sold_date_sk IS NOT NULL 
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING SUM(ss.ss_net_paid) > 10000
),
sales_by_store AS (
    SELECT 
        s.s_store_sk,
        COUNT(DISTINCT ss.ss_ticket_number) AS ticket_count,
        AVG(ss.ss_net_paid_inc_tax) AS avg_ticket_value
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY s.s_store_sk
)
SELECT 
    r.s_store_sk,
    r.ss_ticket_number,
    COALESCE(hc.total_net_paid, 0) AS high_value_customer_net_paid,
    sb.ticket_count AS total_tickets,
    sb.avg_ticket_value
FROM ranked_sales r
LEFT JOIN high_value_customers hc ON r.s_store_sk = hc.c_customer_sk
JOIN sales_by_store sb ON r.s_store_sk = sb.s_store_sk
WHERE r.sales_rank = 1
ORDER BY r.s_store_sk, r.ss_ticket_number DESC
LIMIT 50;
