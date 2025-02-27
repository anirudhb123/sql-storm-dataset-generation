
SELECT
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    COUNT(DISTINCT wr.wr_order_number) AS return_count,
    SUM(wr.wr_return_amt) AS total_return_amount
FROM
    customer c
JOIN
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN
    web_returns wr ON ss.ss_ticket_number = wr.wr_order_number AND c.c_customer_sk = wr.w_returning_customer_sk
JOIN
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE
    d.d_year = 2023
    AND (ca.ca_state IN ('NY', 'CA', 'TX'))
GROUP BY
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state
ORDER BY
    total_sales DESC
LIMIT 100;
