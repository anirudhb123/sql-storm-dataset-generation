
WITH sales_data AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_net_paid_inc_tax) AS avg_net_paid
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 90 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY
        ws_bill_customer_sk
),
customer_info AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_credit_rating,
    ci.cd_purchase_estimate,
    COALESCE(sd.total_net_profit, 0) AS total_net_profit,
    COALESCE(sd.order_count, 0) AS order_count,
    (CASE 
        WHEN ci.cd_purchase_estimate > 1000 THEN 'High Value'
        WHEN ci.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END) AS customer_value_segment
FROM
    customer_info ci
LEFT JOIN
    sales_data sd ON ci.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_customer_sk = sd.ws_bill_customer_sk)
WHERE
    (ci.rank <= 10 OR ci.rank IS NULL)
ORDER BY
    ci.cd_gender, total_net_profit DESC;
