
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_ext_sales_price,
        'web' AS sales_channel,
        1 AS level
    FROM web_sales
    UNION ALL
    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        cs_quantity,
        cs_ext_sales_price,
        'catalog' AS sales_channel,
        sh.level + 1 
    FROM catalog_sales cs
    JOIN sales_hierarchy sh ON cs.cs_item_sk = sh.ws_item_sk
    WHERE sh.level < 3
),
survey_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cd.cd_gender, 'U') AS gender,
        COALESCE(cd.cd_marital_status, 'U') AS marital_status,
        COUNT(DISTINCT sh.ws_item_sk) AS items_purchased,
        SUM(sh.ws_ext_sales_price) AS total_spent
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN sales_hierarchy sh ON c.c_customer_sk = sh.ws_item_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
max_values AS (
    SELECT 
        MAX(total_spent) AS max_spent, 
        MAX(items_purchased) AS max_items
    FROM survey_data
)
SELECT 
    sd.c_customer_sk,
    sd.c_first_name,
    sd.c_last_name,
    sd.gender,
    sd.marital_status,
    sd.items_purchased,
    sd.total_spent,
    CASE 
        WHEN sd.total_spent = mv.max_spent THEN 'Top Spender'
        ELSE 'Regular Customer'
    END AS customer_category
FROM survey_data sd
CROSS JOIN max_values mv
WHERE sd.total_spent IS NOT NULL
AND sd.items_purchased > 0
ORDER BY sd.total_spent DESC
LIMIT 100;
