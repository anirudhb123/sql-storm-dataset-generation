
SELECT
    ca.ca_address_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    c.c_email_address,
    d.d_date AS order_date,
    SUM(ws.ws_sales_price) AS total_sales_amount,
    LISTAGG(DISTINCT CONCAT(cp.cp_catalog_page_id, ': ', cp.cp_description), '; ') WITHIN GROUP (ORDER BY cp.cp_catalog_page_id) AS catalog_details
FROM
    customer c
JOIN
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN
    catalog_page cp ON ws.ws_web_page_sk = cp.cp_catalog_page_sk
WHERE
    d.d_year = 2023
    AND c.c_birth_year >= 1980
    AND c.c_email_address LIKE '%@example.com'
GROUP BY
    ca.ca_address_id, c.c_first_name, c.c_last_name, c.c_email_address, d.d_date
ORDER BY
    total_sales_amount DESC
LIMIT 20;
