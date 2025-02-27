
WITH item_summary AS (
    SELECT
        i.i_item_sk,
        TRIM(UPPER(i.i_item_desc)) AS item_desc,
        SUBSTR(i.i_brand, 1, 20) AS brand_short,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM
        item i
    LEFT JOIN
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE
        LENGTH(TRIM(i.i_item_desc)) > 10
    GROUP BY
        i.i_item_sk, item_desc, brand_short
),
customer_summary AS (
    SELECT
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS lifetime_value
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, full_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
final_summary AS (
    SELECT
        cs.full_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_education_status,
        is.item_desc,
        is.brand_short,
        is.total_orders AS item_orders,
        is.total_quantity_sold,
        is.total_net_profit,
        cs.total_orders AS customer_orders,
        cs.lifetime_value
    FROM
        customer_summary cs
    JOIN
        item_summary is ON cs.total_orders > 0
    ORDER BY
        cs.lifetime_value DESC,
        is.total_net_profit DESC
)
SELECT * FROM final_summary
WHERE customer_orders > 5 AND item_orders > 10
LIMIT 100;
