
WITH RECURSIVE item_hierarchy AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        0 AS level
    FROM item i
    WHERE i.i_current_price IS NOT NULL
    UNION ALL
    SELECT 
        ih.i_item_sk,
        ih.i_item_id,
        ih.i_item_desc,
        ih.i_current_price,
        ih.i_brand,
        ih.level + 1
    FROM item_hierarchy ih
    JOIN item i ON ih.i_item_sk = i.i_item_sk
    WHERE ih.level < 3
),
sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY ws.ws_item_sk
),
customer_gender_distribution AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year >= 1980
    GROUP BY cd.cd_gender
)
SELECT 
    ih.i_item_id,
    ih.i_item_desc,
    ih.i_current_price,
    ss.total_quantity,
    ss.total_sales,
    cd.customer_count,
    (SELECT COUNT(*) FROM customer WHERE c_current_cdemo_sk IS NULL) AS null_demographics_count,
    COALESCE(cd.customer_count, 0) AS female_customers,
    CASE 
        WHEN ih.i_current_price > 100 THEN 'High Price'
        WHEN ih.i_current_price BETWEEN 50 AND 100 THEN 'Medium Price'
        ELSE 'Low Price'
    END AS price_category
FROM item_hierarchy ih
LEFT JOIN sales_summary ss ON ih.i_item_sk = ss.ws_item_sk
LEFT JOIN customer_gender_distribution cd ON cd.cd_gender = 'F'
WHERE ih.i_brand IN (SELECT DISTINCT i_brand FROM item WHERE i_class = 'Electronics')
ORDER BY ih.i_item_id, price_category DESC;
