
WITH sales_summary AS (
    SELECT
        ws_bill_customer_sk AS customer_id,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_net_paid) AS avg_paid,
        COUNT(ws_order_number) AS total_orders,
        COUNT(DISTINCT ws_item_sk) AS unique_items
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                            AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY
        ws_bill_customer_sk
),
demographic_info AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
combined_info AS (
    SELECT
        ds.customer_id,
        di.cd_gender,
        di.cd_marital_status,
        di.cd_education_status,
        ds.total_profit,
        ds.avg_paid,
        ds.total_orders,
        ds.unique_items
    FROM
        sales_summary ds
    LEFT JOIN
        demographic_info di ON ds.customer_id = di.c_customer_id
)
SELECT
    cd_marital_status,
    cd_gender,
    COUNT(DISTINCT customer_id) AS count_customers,
    SUM(total_profit) AS total_profit,
    AVG(avg_paid) AS avg_net_paid,
    AVG(total_orders) AS avg_orders,
    SUM(unique_items) AS total_unique_items
FROM
    combined_info
GROUP BY
    cd_marital_status,
    cd_gender
ORDER BY
    total_profit DESC;
