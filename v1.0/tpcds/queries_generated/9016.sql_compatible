
WITH sales_summary AS (
    SELECT
        ws_sold_date_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws_ship_customer_sk) AS unique_customers
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws_sold_date_sk
),
customer_analysis AS (
    SELECT
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        AVG(cd_dep_count) AS avg_dependents,
        AVG(cd_credit_rating) AS avg_credit_rating
    FROM
        customer_demographics
    JOIN
        customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY
        cd_gender
),
inventory_analysis AS (
    SELECT
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM
        inventory
    GROUP BY
        inv_warehouse_sk
)
SELECT
    ds.d_date AS report_date,
    ss.total_orders,
    ss.total_net_profit,
    ss.total_quantity,
    ca.customer_count,
    ca.total_purchase_estimate,
    ca.avg_dependents,
    ia.total_inventory
FROM
    sales_summary ss
JOIN
    date_dim ds ON ss.ws_sold_date_sk = ds.d_date_sk
JOIN
    customer_analysis ca ON 1=1
JOIN
    inventory_analysis ia ON 1=1
WHERE
    ds.d_year = 2023
ORDER BY
    ds.d_date;
