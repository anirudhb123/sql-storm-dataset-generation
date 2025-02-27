
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ws_sold_date_sk,
        1 AS level
    FROM web_sales
    GROUP BY ws_item_sk, ws_sold_date_sk

    UNION ALL 

    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_sales_price) AS total_sales,
        cs_sold_date_sk,
        level + 1
    FROM catalog_sales
    JOIN sales_summary ON sales_summary.ws_item_sk = cs_item_sk
    GROUP BY cs_item_sk, cs_sold_date_sk, level
),
date_filters AS (
    SELECT 
        d_date_sk,
        d_month_seq,
        d_year,
        d_week_seq
    FROM date_dim
    WHERE d_year = 2023
),
ranked_sales AS (
    SELECT 
        s.ws_item_sk,
        s.total_quantity,
        s.total_sales,
        d.d_month_seq,
        RANK() OVER (PARTITION BY s.ws_item_sk ORDER BY s.total_sales DESC) AS sales_rank
    FROM sales_summary s
    JOIN date_filters d ON s.ws_sold_date_sk = d.d_date_sk
    WHERE s.total_quantity IS NOT NULL
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    r.total_quantity,
    r.total_sales,
    r.sales_rank,
    CASE 
        WHEN r.total_sales > 10000 THEN 'High Value'
        WHEN r.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS sales_category
FROM ranked_sales r
JOIN item i ON r.ws_item_sk = i.i_item_sk
LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_sk = (SELECT cc.cc_call_center_sk FROM call_center cc WHERE cc.cc_call_center_sk = r.ws_item_sk LIMIT 1)) 
WHERE r.sales_rank = 1
ORDER BY r.total_sales DESC
FETCH FIRST 100 ROWS ONLY;
