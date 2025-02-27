
SELECT
    c.c_customer_id,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
    SUM(ss.ss_sales_price) AS total_sales_amount,
    AVG(DATEDIFF(DAY, d.d_date, CURRENT_DATE)) AS days_since_first_purchase
FROM
    customer c
JOIN
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE
    c.c_current_cdemo_sk IS NOT NULL
GROUP BY
    c.c_customer_id
ORDER BY
    total_sales_amount DESC
LIMIT 100;
