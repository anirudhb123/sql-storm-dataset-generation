
WITH RECURSIVE sales_summary AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_sold_date_sk, ws_item_sk
),
item_details AS (
    SELECT
        i_item_sk,
        i_item_desc,
        i_brand,
        i_category
    FROM item
),
customer_info AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS rank_by_purchase
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
top_customers AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ci.cd_gender,
        ci.cd_purchase_estimate
    FROM customer c
    JOIN customer_info ci ON c.c_customer_sk = ci.c_customer_sk
    WHERE ci.rank_by_purchase <= 10
),
warehouse_sales AS (
    SELECT
        w.w_warehouse_sk,
        SUM(ws.ws_sales_price) AS total_sales
    FROM warehouse w
    JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY w.w_warehouse_sk
)
SELECT
    ss.ws_sold_date_sk,
    ss.ws_item_sk,
    id.i_item_desc,
    id.i_brand,
    id.i_category,
    ss.total_quantity,
    ss.total_sales,
    tc.full_name,
    tc.cd_gender,
    tc.cd_purchase_estimate,
    ws.total_sales AS warehouse_total_sales,
    CASE 
        WHEN ss.total_sales IS NULL THEN 'No Sales'
        WHEN ss.total_sales > 500 THEN 'High Sales'
        ELSE 'Regular Sales'
    END AS sales_category
FROM sales_summary ss
LEFT JOIN item_details id ON ss.ws_item_sk = id.i_item_sk
LEFT JOIN top_customers tc ON ss.ws_item_sk IN (
    SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = tc.c_customer_sk
)
LEFT JOIN warehouse_sales ws ON ss.ws_item_sk IN (
    SELECT ws_item_sk FROM web_sales WHERE ws_warehouse_sk = ws.w_warehouse_sk
)
WHERE ss.rn = 1
ORDER BY ss.ws_sold_date_sk, total_sales DESC;
