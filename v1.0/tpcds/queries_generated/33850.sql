
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
item_details AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price,
        i_brand,
        i_category
    FROM item
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_buy_potential, 'UNKNOWN') AS buy_potential
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
sales_ranked AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_sales,
        ss.total_orders,
        ROW_NUMBER() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM sales_summary ss
    WHERE ss.rank = 1
)
SELECT 
    ir.i_item_desc,
    ir.i_current_price,
    ir.i_brand,
    cr.total_sales,
    cr.total_orders,
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.buy_potential
FROM sales_ranked cr
JOIN item_details ir ON cr.ws_item_sk = ir.i_item_sk
JOIN customer_info ci ON ci.c_customer_sk IN (
    SELECT DISTINCT ws_bill_customer_sk 
    FROM web_sales 
    WHERE ws_item_sk = cr.ws_item_sk
)
WHERE cr.total_sales > (SELECT AVG(total_sales) FROM sales_ranked)
    AND ir.i_category LIKE '%Electronics%'
ORDER BY cr.total_sales DESC
LIMIT 10;
