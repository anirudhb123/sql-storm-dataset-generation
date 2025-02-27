
WITH customer_info AS (
    SELECT
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT CASE WHEN sr.sr_order_number IS NOT NULL THEN sr.sr_ticket_number END) AS return_count,
        AVG(CASE WHEN sr.sr_return_quantity > 0 THEN sr.sr_return_amt ELSE NULL END) AS avg_return_amt,
        SUM(CASE WHEN sr.sr_return_quantity > 0 THEN sr.sr_return_quantity ELSE 0 END) AS total_return_qty
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
customer_orders AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id
)
SELECT
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    co.total_net_profit,
    co.order_count,
    co.total_quantity_sold,
    ci.return_count,
    ci.avg_return_amt,
    ci.total_return_qty
FROM
    customer_info ci
JOIN
    customer_orders co ON ci.c_customer_id = co.c_customer_id
WHERE
    ci.cd_gender = 'F'
ORDER BY
    co.total_net_profit DESC
LIMIT 100;
