
SELECT
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_spent,
    AVG(EXTRACT(DAY FROM d.d_date)) AS avg_order_day,
    STRING_AGG(DISTINCT wp.wp_url, ', ') AS visited_web_pages,
    CASE
        WHEN cd.cd_gender = 'F' THEN 'Female'
        WHEN cd.cd_gender = 'M' THEN 'Male'
        ELSE 'Other'
    END AS gender,
    CASE
        WHEN ca.ca_state IS NOT NULL THEN 'Located'
        ELSE 'Not located'
    END AS address_status
FROM
    customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE
    d.d_year = 2023
GROUP BY
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, ca.ca_zip, cd.cd_gender
HAVING
    COUNT(ws.ws_order_number) > 5
ORDER BY
    total_spent DESC
LIMIT 10;
