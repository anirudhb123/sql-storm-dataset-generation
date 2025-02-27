
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(cs.cs_sales_price) AS total_sales,
    COUNT(cs.cs_order_number) AS number_of_orders
FROM
    customer c
JOIN
    store_sales cs ON c.c_customer_sk = cs.ss_customer_sk
WHERE
    cs.ss_sold_date_sk BETWEEN 2451545 AND 2451555
GROUP BY
    c.c_customer_id, c.c_first_name, c.c_last_name
ORDER BY
    total_sales DESC
LIMIT 10;
