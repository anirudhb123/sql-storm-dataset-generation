
WITH RECURSIVE sales_data AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(cd.cd_credit_rating, 'Unknown') AS credit_rating, 
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_ranked AS (
    SELECT
        sd.ws_item_sk,
        sd.total_sales,
        sd.order_count,
        ci.c_customer_sk,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        ci.credit_rating,
        ROW_NUMBER() OVER (PARTITION BY ci.cd_gender ORDER BY sd.total_sales DESC) AS gender_rank
    FROM sales_data sd
    JOIN customer_info ci ON sd.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = ci.c_customer_sk)
)
SELECT
    sr.ws_item_sk,
    sr.total_sales,
    sr.order_count,
    sr.c_customer_sk,
    sr.cd_gender,
    sr.cd_marital_status,
    sr.cd_purchase_estimate,
    sr.credit_rating
FROM sales_ranked sr
WHERE sr.gender_rank <= 10 AND sr.order_count > (
    SELECT AVG(order_count)
    FROM (
        SELECT COUNT(ws_order_number) AS order_count
        FROM web_sales
        GROUP BY ws_item_sk
    ) AS avg_orders
)
ORDER BY sr.total_sales DESC;
