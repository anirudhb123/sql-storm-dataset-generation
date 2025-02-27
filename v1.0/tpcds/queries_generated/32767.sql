
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_item_sk) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= 10000
), 
top_sales AS (
    SELECT 
        order_number,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_item_sk) AS item_count
    FROM sales_cte
    GROUP BY ws_order_number
    HAVING COUNT(ws_item_sk) > 1
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate >= 500
),
joined_data AS (
    SELECT 
        cs.ws_order_number,
        cs.total_sales,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM top_sales cs
    LEFT JOIN customer_data cd ON cd.rn = 1
    WHERE cd.c_customer_sk IS NOT NULL
)

SELECT 
    j.ws_order_number,
    j.total_sales,
    coalesce(j.c_first_name || ' ' || j.c_last_name, 'Unknown') AS customer_name,
    CASE 
        WHEN j.cd_gender = 'M' THEN 'Male'
        WHEN j.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender,
    CASE 
        WHEN j.cd_marital_status IS NULL THEN 'Not Specified'
        ELSE j.cd_marital_status 
    END AS marital_status
FROM joined_data j
WHERE j.total_sales > (SELECT AVG(total_sales) FROM top_sales)
ORDER BY j.total_sales DESC;
