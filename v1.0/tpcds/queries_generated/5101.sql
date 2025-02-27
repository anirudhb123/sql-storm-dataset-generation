
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_purchases
    FROM
        customer c
    JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY
        c.c_customer_id
),
TopCustomers AS (
    SELECT
        c.customer_id,
        cs.total_spent,
        cs.total_purchases,
        RANK() OVER (ORDER BY cs.total_spent DESC) as rank
    FROM
        CustomerSales cs
    JOIN
        customer c ON cs.c_customer_id = c.c_customer_id
)
SELECT
    tc.customer_id,
    tc.total_spent,
    tc.total_purchases,
    d.d_year,
    SUM(ws.ws_net_profit) AS total_profit
FROM
    TopCustomers tc
JOIN
    web_sales ws ON tc.customer_id = ws.ws_bill_customer_sk
JOIN
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE
    tc.rank <= 10
GROUP BY
    tc.customer_id, tc.total_spent, tc.total_purchases, d.d_year
ORDER BY
    d.d_year, tc.total_spent DESC;
