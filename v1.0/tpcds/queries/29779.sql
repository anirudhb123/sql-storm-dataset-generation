
SELECT
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
    SUM(ws.ws_net_paid) AS total_spent,
    STRING_AGG(DISTINCT i.i_item_desc, ', ') AS purchased_items,
    DENSE_RANK() OVER (PARTITION BY ca.ca_city ORDER BY SUM(ws.ws_net_paid) DESC) AS city_rank
FROM customer c
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
WHERE cd.cd_gender = 'F'
AND ca.ca_state IN ('CA', 'TX', 'NY')
AND ws.ws_sold_date_sk BETWEEN 2459000 AND 2459650
GROUP BY c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, cd.cd_gender
HAVING COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY total_spent DESC, city_rank ASC
LIMIT 50;
