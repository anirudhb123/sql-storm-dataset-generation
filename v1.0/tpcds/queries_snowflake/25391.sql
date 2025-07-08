
SELECT
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    LISTAGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') WITHIN GROUP (ORDER BY c.c_first_name, c.c_last_name) AS customer_names,
    SUM(ws.ws_sales_price) AS total_sales,
    EXTRACT(YEAR FROM d.d_date) AS sales_year
FROM
    customer_address ca
JOIN
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE
    ca.ca_state = 'CA' AND
    d.d_year >= 2020
GROUP BY
    ca.ca_city, EXTRACT(YEAR FROM d.d_date)
HAVING
    SUM(ws.ws_sales_price) > 10000
ORDER BY
    total_sales DESC;
