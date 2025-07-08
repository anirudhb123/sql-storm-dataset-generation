
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        1 AS level
    FROM customer c
    WHERE c.c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
sales_data AS (
    SELECT
        ws.ws_sold_date_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        DENSE_RANK() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk
),
best_selling_items AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_value_sold
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_id
    HAVING SUM(ws.ws_quantity) > 100
),
customer_spending AS (
    SELECT 
        cd.cd_demo_sk,
        SUM(ws.ws_sales_price) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM customer_demographics cd
    JOIN web_sales ws ON cd.cd_demo_sk = ws.ws_bill_cdemo_sk
    WHERE cd.cd_marital_status = 'M'
    GROUP BY cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS average_order_value
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE d.d_year = 2022
    GROUP BY d.d_date
)
SELECT 
    a.c_first_name AS customer_first_name,
    a.c_last_name AS customer_last_name,
    c.total_spent AS customer_total_spent,
    b.i_item_id AS item_id,
    b.total_quantity_sold,
    b.total_value_sold,
    ss.total_net_paid,
    ss.average_order_value
FROM customer_hierarchy a
JOIN customer_spending c ON a.c_current_cdemo_sk = c.cd_demo_sk
JOIN best_selling_items b ON b.total_quantity_sold = (SELECT MAX(total_quantity_sold) FROM best_selling_items)
JOIN sales_summary ss ON ss.total_orders = (SELECT MAX(total_orders) FROM sales_summary)
WHERE a.level = 1
ORDER BY c.total_spent DESC, a.c_last_name ASC
FETCH FIRST 5 ROWS ONLY;
