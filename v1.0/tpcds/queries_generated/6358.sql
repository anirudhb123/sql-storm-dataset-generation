
WITH sales_summary AS (
    SELECT 
        s_store_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_sales_price) AS total_sales,
        SUM(ss_ext_discount_amt) AS total_discount,
        AVG(ss_net_profit) AS avg_profit,
        COUNT(DISTINCT ss_ticket_number) AS transaction_count
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN (
        SELECT MAX(d_date_sk) - 30 FROM date_dim
    ) AND (
        SELECT MAX(d_date_sk) FROM date_dim
    )
    GROUP BY s_store_sk
), customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ss.ticket_number) AS purchase_count,
        AVG(ss_net_profit) AS avg_customer_profit
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
), promo_summary AS (
    SELECT 
        p.p_promo_sk,
        COUNT(cs.cs_order_number) AS promo_count,
        SUM(cs.cs_net_profit) AS total_promo_profit
    FROM promotion p
    LEFT JOIN catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    GROUP BY p.p_promo_sk
)
SELECT 
    s.store_id,
    ss.total_quantity,
    ss.total_sales,
    ss.total_discount,
    ss.avg_profit,
    cs.purchase_count,
    cs.avg_customer_profit,
    ps.promo_count,
    ps.total_promo_profit
FROM sales_summary ss
JOIN customer_summary cs ON ss.s_store_sk = cs.c_customer_sk
JOIN promo_summary ps ON ss.s_store_sk = ps.p_promo_sk
JOIN store s ON ss.s_store_sk = s.s_store_sk
ORDER BY ss.total_sales DESC
LIMIT 10;
