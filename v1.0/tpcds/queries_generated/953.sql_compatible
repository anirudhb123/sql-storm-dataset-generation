
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        customer AS c
    JOIN
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighSpenders AS (
    SELECT
        c.customer,
        cs.total_spent,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS spender_rank
    FROM
        (SELECT
             c.c_customer_sk AS customer,
             MAX(cs.total_spent) AS total_spent,
             MAX(cs.order_count) AS order_count
         FROM
             CustomerSales cs
         JOIN
             customer c ON cs.c_customer_sk = c.c_customer_sk
         GROUP BY
             c.c_customer_sk) AS cs
)
SELECT
    c.c_first_name,
    c.c_last_name,
    cs.total_spent,
    cs.order_count,
    r.r_reason_desc,
    (CASE WHEN cs.total_spent IS NULL THEN 'No Spending' ELSE 'Active' END) AS customer_status
FROM
    HighSpenders cs
LEFT JOIN
    reason r ON cs.spender_rank <= 5 AND r.r_reason_sk = cs.customer
LEFT JOIN
    customer c ON cs.customer = c.c_customer_sk
WHERE
    (cs.total_spent > 1000 OR cs.order_count > 5)
    AND r.r_reason_desc IS NOT NULL
ORDER BY
    cs.total_spent DESC;
