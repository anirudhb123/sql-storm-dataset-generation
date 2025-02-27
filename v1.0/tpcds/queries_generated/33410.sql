
WITH RECURSIVE sales_data AS (
    SELECT ws_sold_date_sk, ws_item_sk, ws_quantity, ws_list_price, ws_sales_price, ws_net_profit,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS row_num
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 10000 AND 20000
), ranked_sales AS (
    SELECT ws_sold_date_sk, ws_item_sk, ws_quantity, ws_list_price, ws_sales_price, ws_net_profit
    FROM sales_data
    WHERE row_num = 1
),
total_sales AS (
    SELECT ws_item_sk, SUM(ws_sales_price * ws_quantity) AS total_sales
    FROM web_sales
    GROUP BY ws_item_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        ce.cd_gender, 
        ce.cd_marital_status, 
        ce.cd_birth_year,
        COALESCE(wp.wp_url, 'No Website') AS webpage_url
    FROM customer c
    LEFT JOIN customer_demographics ce ON c.c_current_cdemo_sk = ce.cd_demo_sk
    LEFT JOIN web_page wp ON c.c_customer_sk = wp.wp_customer_sk
),
sales_by_customer AS (
    SELECT ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.cd_marital_status,
           cs.total_sales, COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer_info ci
    JOIN web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    JOIN total_sales cs ON ws.ws_item_sk = cs.ws_item_sk
    GROUP BY ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.cd_marital_status, cs.total_sales
)
SELECT 
    cb.c_customer_id,
    cb.c_first_name || ' ' || cb.c_last_name AS full_name,
    cb.cd_gender,
    cb.cd_marital_status,
    cb.total_sales,
    cb.order_count,
    CASE 
        WHEN cb.total_sales IS NULL THEN 'No Sales'
        WHEN cb.total_sales > 10000 THEN 'High Value Customer'
        ELSE 'Standard Customer'
    END AS customer_type
FROM sales_by_customer cb
LEFT JOIN customer c ON cb.c_customer_sk = c.c_customer_sk
ORDER BY cb.total_sales DESC
LIMIT 10;
