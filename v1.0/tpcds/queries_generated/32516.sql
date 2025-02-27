
WITH RECURSIVE sales_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, 0 AS level
    FROM customer
    WHERE c_customer_sk = (SELECT MIN(c_customer_sk) FROM customer)
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, sh.level + 1
    FROM customer c
    JOIN sales_hierarchy sh ON c.c_current_cdemo_sk = sh.c_customer_sk
), 
aggregated_sales AS (
    SELECT 
        s.ss_item_sk, 
        SUM(s.ss_quantity) AS total_quantity, 
        SUM(s.ss_net_paid) AS total_sales,
        ROW_NUMBER() OVER(PARTITION BY s.ss_item_sk ORDER BY SUM(s.ss_quantity) DESC) AS rn
    FROM store_sales s
    INNER JOIN customer c ON s.ss_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year IS NOT NULL 
    GROUP BY s.ss_item_sk
),
top_sales AS (
    SELECT *
    FROM aggregated_sales
    WHERE rn <= 10
),
item_promotions AS (
    SELECT 
        i.i_item_sk,
        p.p_promo_name,
        COUNT(p.p_promo_sk) AS promo_count
    FROM item i
    LEFT JOIN promotion p ON i.i_item_sk = p.p_item_sk
    GROUP BY i.i_item_sk, p.p_promo_name
),
final_results AS (
    SELECT 
        sh.c_first_name, 
        sh.c_last_name, 
        ts.total_quantity, 
        ts.total_sales,
        ip.promo_count
    FROM sales_hierarchy sh
    FULL OUTER JOIN top_sales ts ON sh.c_customer_sk IS NOT NULL
    FULL OUTER JOIN item_promotions ip ON ts.ss_item_sk = ip.i_item_sk
)
SELECT 
    COALESCE(sh.c_first_name, 'Unknown') AS customer_first_name,
    COALESCE(sh.c_last_name, 'Unknown') AS customer_last_name,
    COALESCE(ts.total_quantity, 0) AS total_quantity,
    COALESCE(ts.total_sales, 0.00) AS total_sales,
    COALESCE(ip.promo_count, 0) AS total_promotions
FROM final_results
WHERE (customer_first_name IS NOT NULL OR customer_last_name IS NOT NULL)
ORDER BY total_sales DESC, total_quantity ASC;
