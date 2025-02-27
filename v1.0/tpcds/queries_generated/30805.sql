
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rn
    FROM web_sales
    GROUP BY ws_item_sk
),
customer_cte AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) AS customer_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
aggregate_sales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(ss.total_quantity, 0) AS total_quantity,
        COALESCE(ss.total_sales, 0) AS total_sales,
        CASE 
            WHEN COALESCE(ss.total_sales, 0) > 0 THEN ss.total_sales 
            ELSE NULL 
        END AS sales_value,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM item
    LEFT JOIN sales_cte ss ON item.i_item_sk = ss.ws_item_sk
    LEFT JOIN store_sales s ON s.ss_item_sk = item.i_item_sk
    LEFT JOIN customer c ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY item.i_item_id, item.i_item_desc
),
sales_analysis AS (
    SELECT 
        ag.i_item_id,
        ag.i_item_desc,
        ag.total_quantity,
        ag.total_sales,
        ag.customer_count,
        CASE 
            WHEN ag.total_sales > 1000 THEN 'High Performer'
            WHEN ag.total_sales BETWEEN 500 AND 1000 THEN 'Average Performer'
            ELSE 'Low Performer' 
        END AS performance_category
    FROM aggregate_sales ag
)
SELECT 
    sa.i_item_id,
    sa.i_item_desc,
    sa.total_quantity,
    sa.total_sales,
    sa.customer_count,
    sa.performance_category,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status
FROM sales_analysis sa
JOIN customer_cte cd ON sa.customer_count > 0
WHERE cd.customer_rank <= 5
ORDER BY sa.total_sales DESC
LIMIT 20;
