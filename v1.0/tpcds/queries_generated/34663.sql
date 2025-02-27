
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        1 AS level
    FROM customer_demographics
    WHERE cd_demo_sk IS NOT NULL

    UNION ALL

    SELECT 
        d.cd_demo_sk,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate,
        sh.level + 1
    FROM customer_demographics d
    INNER JOIN sales_hierarchy sh ON d.cd_demo_sk = sh.cd_demo_sk + 1
),
item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
store_sales_summary AS (
    SELECT
        ss.ss_item_sk,
        SUM(ss.ss_sales_price) AS total_store_sales
    FROM store_sales ss
    GROUP BY ss.ss_item_sk
),
combined_sales AS (
    SELECT 
        is.ws_item_sk,
        is.total_sales + COALESCE(sss.total_store_sales, 0) AS combined_total_sales,
        is.order_count
    FROM item_sales is
    LEFT JOIN store_sales_summary sss ON is.ws_item_sk = sss.ss_item_sk
),
top_items AS (
    SELECT 
        cs.ws_item_sk,
        cs.combined_total_sales,
        ROW_NUMBER() OVER (ORDER BY cs.combined_total_sales DESC) AS sales_rank
    FROM combined_sales cs
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    ARRAY_AGG(DISTINCT ti.ws_item_sk) AS top_items_sold
FROM top_items ti
JOIN customer c ON c.c_current_cdemo_sk = ti.ws_item_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE ti.sales_rank <= 10 
AND ca.ca_state = 'CA'
GROUP BY ca.ca_city
ORDER BY customer_count DESC;
