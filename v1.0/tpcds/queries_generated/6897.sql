
WITH ranked_customers AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS rank_within_gender
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        cd.cd_marital_status = 'M' AND
        cd.cd_purchase_estimate > 10000
    GROUP BY
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
customer_analysis AS (
    SELECT
        rc.c_customer_id,
        rc.c_first_name,
        rc.c_last_name,
        rc.total_spent,
        rc.total_orders,
        cd.ca_city,
        cd.ca_state,
        cd.ca_country
    FROM
        ranked_customers rc
    JOIN
        customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_id = rc.c_customer_id)
    JOIN
        date_dim dd ON dd.d_date_sk = (SELECT MIN(ws.ws_sold_date_sk) FROM web_sales ws WHERE ws.ws_bill_customer_sk = rc.c_customer_id)
    WHERE
        rc.rank_within_gender <= 10
)
SELECT
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    COUNT(*) AS customer_count,
    AVG(total_spent) AS avg_spent
FROM
    customer_analysis ca
GROUP BY
    ca.ca_city, ca.ca_state, ca.ca_country
ORDER BY
    customer_count DESC
LIMIT 10;
