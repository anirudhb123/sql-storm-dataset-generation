
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
top_items AS (
    SELECT 
        i_item_sk,
        i_product_name,
        COALESCE(ss.total_quantity, 0) AS total_quantity,
        COALESCE(ss.total_sales, 0) AS total_sales
    FROM item
    LEFT JOIN sales_summary ss ON item.i_item_sk = ss.ws_item_sk
    WHERE ss.sales_rank <= 10 OR ss.sales_rank IS NULL
),
customer_demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_income_band_sk
    FROM customer_demographics
    WHERE cd_marital_status = 'M' AND cd_gender = 'F'
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_email_address, cd.cd_income_band_sk
),
final_summary AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.c_email_address,
        ci.orders_count,
        ti.i_product_name,
        ti.total_quantity,
        ti.total_sales
    FROM customer_info ci
    JOIN top_items ti ON ci.orders_count > 0
)
SELECT 
    fs.c_customer_sk,
    fs.c_first_name,
    fs.c_last_name,
    fs.c_email_address,
    fs.orders_count,
    fs.i_product_name,
    fs.total_quantity,
    fs.total_sales,
    CASE 
        WHEN fs.total_sales > 1000 THEN 'High Value'
        WHEN fs.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS value_category
FROM final_summary fs
WHERE fs.total_quantity IS NOT NULL
ORDER BY fs.total_sales DESC
LIMIT 50;
