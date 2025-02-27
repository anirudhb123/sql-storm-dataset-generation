
SELECT
    c.c_customer_id,
    SUM(ss.net_paid) AS total_spent,
    COUNT(ss.ticket_number) AS purchase_count,
    MAX(ss.sold_date_sk) AS last_purchase_date
FROM
    customer c
JOIN
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE
    c.c_birth_year BETWEEN 1980 AND 2000
GROUP BY
    c.c_customer_id
ORDER BY
    total_spent DESC
LIMIT 100;
