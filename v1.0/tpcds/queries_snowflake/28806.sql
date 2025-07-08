
SELECT
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_spent,
    LISTAGG(DISTINCT i.i_product_name, ', ') AS purchased_items
FROM
    customer c
JOIN
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE
    ca.ca_country = 'USA'
    AND c.c_birth_year BETWEEN 1970 AND 1990
GROUP BY
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING
    SUM(ws.ws_net_paid) > 1000
ORDER BY
    total_spent DESC;
