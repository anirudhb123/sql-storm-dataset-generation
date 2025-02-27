
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss_store_sk AS store_id,
        SUM(ss_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid) DESC) AS rank
    FROM store_sales
    WHERE ss_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY ss_store_sk
    HAVING SUM(ss_net_paid) > 1000
),
top_stores AS (
    SELECT store_id, total_sales
    FROM sales_hierarchy
    WHERE rank <= 5
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT ws.ws_item_sk) AS distinct_items_purchased
    FROM customer c
    INNER JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
final_summary AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_web_sales,
        cs.web_order_count,
        cs.distinct_items_purchased,
        CASE 
            WHEN cs.total_web_sales >= 5000 THEN 'High Value'
            WHEN cs.total_web_sales BETWEEN 1000 AND 5000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value,
        th.total_sales AS store_sales
    FROM customer_sales cs
    LEFT JOIN top_stores th ON th.store_id = (SELECT ss_store_sk FROM store WHERE s_store_sk = cs.c_customer_sk LIMIT 1)
)
SELECT 
    f.customer_value,
    COUNT(f.c_customer_sk) AS customer_count,
    AVG(f.total_web_sales) AS avg_web_sales,
    SUM(f.store_sales) AS total_store_sales
FROM final_summary f
GROUP BY f.customer_value
ORDER BY customer_value DESC;
