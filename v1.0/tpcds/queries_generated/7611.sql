
WITH customer_sales AS (
    SELECT
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_net_paid) AS avg_order_value,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450600 -- Example date range
    GROUP BY
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
top_customers AS (
    SELECT
        c_customer_id,
        total_orders,
        total_profit,
        total_quantity,
        avg_order_value,
        RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
    FROM
        customer_sales
)
SELECT
    tc.c_customer_id,
    tc.total_orders,
    tc.total_profit,
    tc.total_quantity,
    tc.avg_order_value,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status
FROM
    top_customers tc
JOIN
    customer_demographics cd ON tc.c_customer_id = cd.cd_demo_sk
WHERE
    tc.profit_rank <= 10 -- Top 10 customers by profit
ORDER BY
    tc.total_profit DESC;
