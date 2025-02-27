
WITH CustomerDetails AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
PurchaseSummary AS (
    SELECT
        cd.c_customer_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM
        web_sales ws
    JOIN
        CustomerDetails cd ON ws.ws_bill_customer_sk = cd.c_customer_id
    GROUP BY
        cd.c_customer_id
),
EngagementMetrics AS (
    SELECT
        cd.c_customer_id,
        cd.full_name,
        cd.ca_city,
        cd.ca_state,
        ps.total_orders,
        ps.total_spent,
        CASE
            WHEN ps.total_spent > 1000 THEN 'High Value'
            WHEN ps.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_category
    FROM
        CustomerDetails cd
    LEFT JOIN
        PurchaseSummary ps ON cd.c_customer_id = ps.c_customer_id
)
SELECT
    em.full_name,
    em.ca_city,
    em.ca_state,
    em.total_orders,
    em.total_spent,
    em.customer_value_category
FROM
    EngagementMetrics em
WHERE
    em.total_orders IS NOT NULL
ORDER BY
    em.total_spent DESC;
