
WITH RECURSIVE sales_summary AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
top_items AS (
    SELECT
        item.i_item_id,
        item.i_item_desc,
        summary.total_quantity,
        summary.total_sales
    FROM
        sales_summary summary
    JOIN
        item ON summary.ws_item_sk = item.i_item_sk
    WHERE
        summary.rank <= 5
),
customer_info AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
),
sales_by_customer AS (
    SELECT
        ci.c_customer_id,
        ci.total_orders,
        SUM(ss.total_sales) AS customer_total_sales
    FROM
        customer_info ci
    JOIN
        web_sales ws ON ci.c_customer_id = ws.ws_bill_customer_sk
    JOIN
        sales_summary ss ON ws.ws_item_sk = ss.ws_item_sk
    WHERE
        ci.total_orders > 0
    GROUP BY
        ci.c_customer_id, ci.total_orders
)

SELECT
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.total_orders,
    ci.income_band,
    COALESCE(sbc.customer_total_sales, 0) AS total_sales,
    ti.total_quantity,
    ti.total_sales AS top_item_sales
FROM
    customer_info ci
LEFT JOIN
    sales_by_customer sbc ON ci.c_customer_id = sbc.c_customer_id
LEFT JOIN
    top_items ti ON ti.i_item_id = (SELECT i_item_id FROM top_items ORDER BY total_sales DESC LIMIT 1)
WHERE
    (ci.total_orders > 5 OR ci.income_band = 0)
ORDER BY
    ci.total_orders DESC, ci.c_last_name ASC;
