
WITH RECURSIVE sales_with_returns AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_item_sk
    UNION ALL
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_sold,
        SUM(cr_return_amount) AS total_sales,
        COUNT(cr_order_number) AS total_orders
    FROM catalog_returns
    GROUP BY cr_item_sk
), item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        i.i_current_price,
        COALESCE(s.total_sold, 0) AS total_quantity_sold,
        COALESCE(s.total_sales, 0) AS total_sales_value,
        COALESCE(s.total_orders, 0) AS total_orders_count
    FROM item i
    LEFT JOIN sales_with_returns s ON i.i_item_sk = s.ws_item_sk
), customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY hd.hd_income_band_sk) AS gender_income_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
), purchase_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_web_orders,
        SUM(ws_net_paid_inc_tax) AS total_web_spent
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    i.i_product_name, 
    SUM(i.total_quantity_sold) AS total_units_sold,
    SUM(i.total_sales_value) AS total_revenue,
    AVG(i.i_current_price) AS average_price,
    cd.c_first_name, 
    cd.c_last_name, 
    cd.cd_gender,
    ps.total_web_orders,
    ps.total_web_spent
FROM item_details i
JOIN customer_details cd ON cd.gender_income_rank <= 5
LEFT JOIN purchase_summary ps ON cd.c_customer_sk = ps.c_customer_sk
GROUP BY i.i_product_name, cd.c_first_name, cd.c_last_name, cd.cd_gender, ps.total_web_orders, ps.total_web_spent
ORDER BY total_revenue DESC
LIMIT 100;
