
WITH customer_orders AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
                                AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        c.c_customer_id
), high_value_customers AS (
    SELECT
        c.c_customer_id,
        co.total_net_profit,
        co.order_count,
        co.avg_sales_price,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM
        customer_orders co
    JOIN customer_demographics cd ON co.c_customer_id = cd.cd_demo_sk
    WHERE
        co.total_net_profit > 10000
)
SELECT
    hvc.c_customer_id,
    hvc.total_net_profit,
    hvc.order_count,
    hvc.avg_sales_price,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.cd_education_status,
    ca.ca_city,
    ca.ca_state
FROM
    high_value_customers hvc
JOIN customer_address ca ON hvc.c_customer_id = ca.ca_address_id
WHERE
    ca.ca_state IN ('CA', 'NY')
ORDER BY
    hvc.total_net_profit DESC
LIMIT 50;
