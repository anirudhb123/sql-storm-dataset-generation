
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        WS_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY WS_net_profit DESC) AS profit_rank
    FROM web_sales
    WHERE ws_sales_price > 0
),
category_sales AS (
    SELECT 
        i_category,
        SUM(ws_net_profit) AS total_profit
    FROM ranked_sales
    JOIN item ON ranked_sales.ws_item_sk = item.i_item_sk
    GROUP BY i_category
),
high_profit_categories AS (
    SELECT 
        i_category,
        total_profit
    FROM category_sales
    WHERE total_profit > (SELECT AVG(total_profit) FROM category_sales) 
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_first_name) AS name_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    hpc.i_category,
    hpc.total_profit
FROM high_profit_categories hpc
JOIN customer_info ci ON ci.name_rank <= 10
WHERE hpc.i_category IS NULL
OR ci.c_last_name NOT LIKE 'A%' 
UNION ALL
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    hpc.i_category,
    hpc.total_profit
FROM customer_info ci
JOIN high_profit_categories hpc ON ci.c_last_name LIKE 'A%'
WHERE EXISTS (
    SELECT 1 
    FROM store_sales ss 
    WHERE ss.ss_item_sk IN (SELECT ws_item_sk FROM ranked_sales WHERE profit_rank <= 3)
    AND ss.ss_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_year = 'Y')
)
ORDER BY hpc.total_profit DESC NULLS LAST;
