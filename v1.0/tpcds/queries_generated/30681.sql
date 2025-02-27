
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c_current_cdemo_sk = ch.c_customer_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS total_sales_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ws.ws_item_sk
),
TopItems AS (
    SELECT 
        si.i_item_id,
        si.i_item_desc,
        sd.total_quantity,
        sd.total_sales_price,
        sd.total_sales_orders
    FROM SalesData sd
    JOIN item si ON sd.ws_item_sk = si.i_item_sk
    WHERE sd.sales_rank <= 10
)
SELECT 
    ch.c_first_name, 
    ch.c_last_name, 
    ti.i_item_id, 
    ti.i_item_desc, 
    ti.total_quantity, 
    ti.total_sales_price, 
    CASE 
        WHEN ti.total_sales_price IS NULL THEN 'N/A'
        ELSE ROUND(ti.total_sales_price / NULLIF(ti.total_quantity, 0), 2) 
    END AS avg_price
FROM CustomerHierarchy ch
LEFT JOIN TopItems ti ON ch.c_current_cdemo_sk = ti.total_quantity
WHERE ch.level = 1 OR (ch.level = 2 AND (ch.c_current_cdemo_sk IS NOT NULL AND ch.c_current_cdemo_sk IN (SELECT cd_demo_sk FROM customer_demographics WHERE cd_marital_status = 'M')))
ORDER BY ti.total_sales_price DESC, ch.c_last_name, ch.c_first_name;
