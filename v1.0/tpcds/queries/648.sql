
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        AVG(ws.ws_net_paid_inc_tax) AS avg_spent
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY
        c.c_customer_id
),
TopCustomers AS (
    SELECT
        c.c_customer_id,
        cs.total_orders,
        cs.total_spent,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM
        CustomerSales cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
    WHERE
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSales)
)
SELECT
    tc.c_customer_id,
    tc.total_orders,
    tc.total_spent,
    CASE
        WHEN tc.total_spent BETWEEN 1000 AND 5000 THEN 'Medium Spender'
        WHEN tc.total_spent > 5000 THEN 'High Spender'
        ELSE 'Low Spender'
    END AS spending_category,
    ca.ca_city,
    ca.ca_state
FROM
    TopCustomers tc
LEFT JOIN customer_address ca ON ca.ca_address_sk = (
    SELECT c.c_current_addr_sk
    FROM customer c
    WHERE c.c_customer_id = tc.c_customer_id
)
WHERE
    ca.ca_state IS NOT NULL
ORDER BY
    tc.customer_rank;
