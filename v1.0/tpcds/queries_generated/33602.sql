
WITH RECURSIVE sales_cte AS (
    SELECT 
        cs_item_sk, 
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(cs_order_number) AS order_count,
        1 AS level
    FROM catalog_sales
    GROUP BY cs_item_sk
    
    UNION ALL
    
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        level + 1
    FROM web_sales
    JOIN sales_cte ON sales_cte.cs_item_sk = ws_item_sk
    GROUP BY ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        si.cs_item_sk,
        SUM(si.total_sales) AS aggregate_sales,
        SUM(si.order_count) AS total_orders,
        ci.customer_name,
        ci.cd_gender
    FROM sales_cte si
    LEFT JOIN customer_info ci ON si.cs_item_sk = ci.c_customer_sk
    GROUP BY si.cs_item_sk, ci.customer_name, ci.cd_gender
)
SELECT 
    ss.cs_item_sk,
    ss.aggregate_sales,
    ss.total_orders,
    ss.customer_name,
    ss.cd_gender,
    ROW_NUMBER() OVER (PARTITION BY ss.cd_gender ORDER BY ss.aggregate_sales DESC) AS sales_rank,
    CASE 
        WHEN ss.aggregate_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status
FROM sales_summary ss
WHERE 
    ss.aggregate_sales > 10000
    OR (ss.customer_name IS NULL AND ss.cd_gender IS NOT NULL)
ORDER BY ss.aggregate_sales DESC;

```
