
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        1 AS level,
        NULL AS parent_store_sk
    FROM store
    WHERE s_state = 'CA'
    
    UNION ALL
    
    SELECT 
        s2.s_store_sk,
        s2.s_store_name,
        sh.level + 1,
        sh.s_store_sk
    FROM store s2
    JOIN sales_hierarchy sh ON s2.s_manager_id = sh.s_store_sk
),
sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(*) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2458749 AND 2458975
    GROUP BY ws_item_sk
),
customer_stats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd_dep_count) AS max_dependents
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd_gender
)
SELECT 
    s.s_store_name, 
    COALESCE(sales.item_id, 'N/A') AS item_id,
    ss.total_sales,
    ss.total_transactions,
    cs.cd_gender,
    cs.total_customers,
    cs.avg_purchase_estimate,
    cs.max_dependents,
    STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names,
    CASE 
        WHEN cs.avg_purchase_estimate > 1000 THEN 'High Value'
        WHEN cs.avg_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM store s
LEFT JOIN sales_hierarchy sh ON s.s_store_sk = sh.s_store_sk
LEFT JOIN (
    SELECT 
        ws_item_sk AS item_id, 
        total_sales, 
        total_transactions
    FROM sales_summary
    WHERE sales_rank = 1
) sales ON sales.item_id = (
    SELECT TOP 1 ws_item_sk 
    FROM web_sales 
    WHERE ws_net_paid_inc_tax > 100
    ORDER BY ws_net_paid_inc_tax DESC
)
LEFT JOIN customer_stats cs ON cs.cd_gender = 'M'
GROUP BY 
    s.s_store_name, 
    sales.item_id,
    ss.total_sales,
    ss.total_transactions,
    cs.cd_gender,
    cs.total_customers,
    cs.avg_purchase_estimate,
    cs.max_dependents
ORDER BY total_sales DESC, s.s_store_name;
