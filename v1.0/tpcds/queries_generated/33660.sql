
WITH RECURSIVE sales_data AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        SUM(ws_net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws_item_sk, ws_order_number
),
customer_summary AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws_net_paid) AS total_paid,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM
        customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT
        cs.c_customer_id,
        cs.total_paid,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_paid DESC) AS customer_rank
    FROM
        customer_summary AS cs
),
inventory_status AS (
    SELECT
        inv.inv_item_sk,
        SUM(CASE WHEN inv.inv_quantity_on_hand IS NULL THEN 0 ELSE inv.inv_quantity_on_hand END) AS total_inventory,
        COUNT(DISTINCT inv.inv_warehouse_sk) AS warehouse_count
    FROM
        inventory AS inv
    GROUP BY
        inv.inv_item_sk
)
SELECT
    tc.c_customer_id,
    tc.total_paid,
    tc.total_orders,
    is.total_inventory,
    is.warehouse_count,
    sd.total_sales,
    sd.sales_rank
FROM
    top_customers AS tc
JOIN inventory_status AS is ON tc.total_paid > 1000
LEFT JOIN sales_data AS sd ON tc.total_paid = sd.total_sales
WHERE
    tc.customer_rank <= 10
ORDER BY
    tc.total_paid DESC, sd.sales_rank ASC;
