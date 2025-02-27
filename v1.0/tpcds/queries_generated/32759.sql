
WITH RECURSIVE sales_hierarchy AS (
    SELECT
        s_store_sk,
        s_store_name,
        s_sales_price,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY s_sales_price DESC) AS rank
    FROM (
        SELECT 
            ss.sold_date_sk,
            ss.ss_store_sk,
            ss.ss_sales_price
        FROM store_sales ss
        WHERE ss.ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim) - 10 -- last 10 days of sales
    ) AS sales_data
), top_stores AS (
    SELECT
        sh.s_store_sk,
        sh.s_store_name,
        SUM(ss.ss_net_paid) AS total_net_paid
    FROM sales_hierarchy sh
    JOIN store_sales ss ON sh.s_store_sk = ss.ss_store_sk
    WHERE sh.rank <= 3
    GROUP BY sh.s_store_sk, sh.s_store_name
), customer_stats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ss.ss_item_sk) AS items_purchased,
        SUM(ss.ss_net_paid) AS total_spent
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
), high_spenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.items_purchased,
        cs.total_spent,
        ROW_NUMBER() OVER (ORDER BY cs.total_spent DESC) AS spender_rank
    FROM customer_stats cs
    WHERE cs.total_spent > 1000
)
SELECT 
    s.store_name,
    SUM(sp.total_spent) AS total_spent,
    AVG(sp.items_purchased) AS avg_items_per_customer,
    COUNT(distinct sp.c_customer_sk) as unique_customers
FROM top_stores s
JOIN high_spenders sp ON s.s_store_sk = sp.c_customer_sk
GROUP BY s.store_name
HAVING SUM(sp.total_spent) > 50000
ORDER BY total_spent DESC;
