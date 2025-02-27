
WITH RECURSIVE sales_data AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rn
    FROM
        web_sales
    WHERE
        ws_ship_date_sk IS NOT NULL
),
top_sales AS (
    SELECT
        item.i_item_id,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_sales,
        COUNT(DISTINCT sd.ws_order_number) AS order_count
    FROM
        sales_data sd
    JOIN
        item item ON sd.ws_item_sk = item.i_item_sk
    WHERE
        sd.rn <= 5
    GROUP BY
        item.i_item_id
),
customer_info AS (
    SELECT
        c.c_customer_id,
        c.c_birth_month,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id, c.c_birth_month, cd.cd_gender
    HAVING
        SUM(ws.ws_net_paid) IS NOT NULL
),
sales_summary AS (
    SELECT
        ci.c_customer_id,
        ci.c_birth_month,
        ci.cd_gender,
        COALESCE(ts.total_sales, 0) AS top_sales_value
    FROM
        customer_info ci
    LEFT JOIN
        top_sales ts ON ci.c_customer_id = (
            SELECT DISTINCT
                ws_bill_customer_sk
            FROM
                web_sales
            WHERE
                ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_item_id = (
                    SELECT MAX(i_item_id)
                    FROM item
                    WHERE i_current_price > 20.00
                    )
                )
        )
)
SELECT
    ss.c_customer_id,
    ss.c_birth_month,
    ss.cd_gender,
    ss.top_sales_value,
    CASE
        WHEN ss.top_sales_value > 1000 THEN 'High Spender'
        WHEN ss.top_sales_value BETWEEN 500 AND 1000 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS spending_category
FROM
    sales_summary ss
JOIN
    customer Demographics cd ON ss.c_customer_id = cd.cd_demo_sk
ORDER BY
    ss.top_sales_value DESC NULLS LAST
LIMIT 50;
