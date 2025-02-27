
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
store_info AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        SUM(ss_net_paid) AS store_total_sales
    FROM store 
    JOIN store_sales ON s_store_sk = ss_store_sk
    GROUP BY s_store_sk, s_store_name, s_number_employees
),
customer_info AS (
    SELECT
        c_customer_sk,
        COUNT(DISTINCT s_store_sk) AS store_count,
        MAX(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS is_married,
        SUM(CASE WHEN ws_ship_date_sk IS NOT NULL THEN 1 ELSE 0 END) AS total_orders
    FROM customer
    LEFT JOIN store_sales ON c_customer_sk = ss_customer_sk
    LEFT JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY c_customer_sk
)
SELECT 
    ci.c_customer_sk,
    ci.store_count,
    ci.is_married,
    ss.total_quantity,
    ss.total_net_paid,
    si.s_store_name,
    si.s_number_employees,
    si.store_total_sales
FROM customer_info ci
LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_sold_date_sk
JOIN store_info si ON si.s_store_sk = ss.ws_item_sk 
WHERE (ci.is_married = 1 AND ci.total_orders > 5)
   OR (ci.store_count > 2)
ORDER BY ss.total_net_paid DESC, ci.store_count DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
