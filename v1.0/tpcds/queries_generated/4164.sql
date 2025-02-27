
WITH sales_summary AS (
    SELECT
        ws.warehouse_sk,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        COUNT(DISTINCT ws.ship_customer_sk) AS unique_customers
    FROM
        web_sales ws
    JOIN
        inventory inv ON ws.ws_item_sk = inv.inv_item_sk
    WHERE
        inv.inv_quantity_on_hand > 0
    GROUP BY
        ws.warehouse_sk
),
promotion_details AS (
    SELECT
        p.promo_sk,
        p.promo_name,
        p.discount_active,
        SUM(cs.net_profit) AS total_profit_generated
    FROM
        promotion p
    JOIN
        catalog_sales cs ON p.promo_sk = cs.promo_sk
    GROUP BY
        p.promo_sk, p.promo_name, p.discount_active
),
customer_demographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.gender,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        SUM(ws.net_profit) AS total_spent
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        cd.cd_demo_sk, cd.gender
)
SELECT
    ss.warehouse_sk,
    ss.total_net_profit,
    ss.total_orders,
    ss.unique_customers,
    COALESCE(pd.total_profit_generated, 0) AS total_profit_generated,
    cd.gender,
    cd.total_orders AS customer_orders,
    cd.total_spent AS customer_spent
FROM
    sales_summary ss
LEFT JOIN
    promotion_details pd ON ss.total_net_profit > pd.total_profit_generated
FULL OUTER JOIN
    customer_demographics cd ON ss.unique_customers = cd.total_orders
WHERE
    ss.total_net_profit > 1000 AND (cd.gender = 'M' OR cd.gender IS NULL)
ORDER BY
    ss.warehouse_sk, cd.total_spent DESC;
