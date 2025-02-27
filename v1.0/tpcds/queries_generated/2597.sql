
WITH ranked_sales AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_ship_date_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
customer_summary AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_spent
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
),
popular_items AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM
        item i
    JOIN
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE
        ws.ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY
        i.i_item_sk, i.i_product_name
    HAVING
        SUM(ws.ws_quantity) > 100
)
SELECT
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    COALESCE(hd.hd_income_band_sk, -1) AS income_band,
    SUM(ps.total_spent) AS lifetime_value,
    (SELECT COUNT(DISTINCT ws_order_number) FROM web_sales WHERE ws_bill_customer_sk = cs.c_customer_sk) AS order_count,
    ARRAY_AGG(pi.i_product_name) AS favorite_products
FROM
    customer_summary cs
LEFT JOIN
    household_demographics hd ON cs.c_customer_sk = hd.hd_demo_sk
LEFT JOIN
    ranked_sales rs ON cs.c_customer_sk = rs.ws_order_number
LEFT JOIN
    popular_items pi ON pi.i_item_sk = rs.ws_item_sk
GROUP BY
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    hd.hd_income_band_sk
ORDER BY
    lifetime_value DESC
LIMIT 10;
