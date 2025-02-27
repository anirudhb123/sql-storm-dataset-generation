
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_id, i_brand, i_class, i_category, 0 AS level
    FROM item
    WHERE i_current_price > 20.00
    UNION ALL
    SELECT ih.i_item_sk, ih.i_item_id, ih.i_brand, ih.i_class, ih.i_category, ih.level + 1
    FROM item_hierarchy ih
    JOIN item i ON ih.i_item_sk = i.i_item_sk AND ih.level < 5
), 
sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        COUNT(*) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_ext_sales_price) AS avg_order_value,
        MAX(ws_sold_date_sk) AS last_order_date
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_bill_customer_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        s.total_orders,
        s.total_sales,
        s.avg_order_value,
        s.last_order_date
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN sales_summary s ON c.c_customer_sk = s.ws_bill_customer_sk
    WHERE cd.cd_gender IS NOT NULL
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    COUNT(DISTINCT cr.cr_order_number) AS total_catalog_returns,
    SUM(cr.cr_return_amount) AS total_returned_amount,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    CASE 
        WHEN ci.total_sales IS NULL THEN 'No sales'
        ELSE 'Has sales'
    END AS sales_status,
    STRING_AGG(DISTINCT h.hd_buy_potential, ', ') AS purchase_potential,
    COUNT(DISTINCT ih.i_item_id) FILTER (WHERE ih.level = 0) AS count_high_value_items
FROM customer_info ci
LEFT JOIN catalog_returns cr ON ci.c_customer_sk = cr.cr_returning_customer_sk
LEFT JOIN household_demographics h ON ci.c_customer_sk = h.hd_demo_sk
LEFT JOIN item_hierarchy ih ON ci.c_customer_sk IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales WHERE ws_quantity > 5)
GROUP BY ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.cd_marital_status
ORDER BY total_sales DESC NULLS LAST;
