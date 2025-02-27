
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk, 1 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL

    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk
    WHERE ch.level < 5
),
SalesData AS (
    SELECT ws.ws_ship_date_sk, ws.ws_item_sk, SUM(ws.ws_quantity) AS total_quantity, AVG(ws.ws_net_paid) AS avg_net_paid
    FROM web_sales ws
    GROUP BY ws.ws_ship_date_sk, ws.ws_item_sk
    HAVING SUM(ws.ws_quantity) > 100
),
Demographics AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_department
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE cd.cd_gender IS NOT NULL
),
RevenueByItem AS (
    SELECT i.i_item_id, SUM(ws.ws_sales_price) AS total_revenue
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_id
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    da.ca_city,
    da.ca_state,
    SUM(sd.total_quantity) AS total_sales_quantity,
    AVG(sd.avg_net_paid) AS average_net_paid,
    rb.total_revenue
FROM CustomerHierarchy ch
JOIN customer_address da ON ch.c_current_addr_sk = da.ca_address_sk
LEFT JOIN SalesData sd ON ch.c_customer_sk = sd.ws_ship_date_sk
LEFT JOIN RevenueByItem rb ON sd.ws_item_sk = rb.i_item_id
WHERE da.ca_country = 'USA' AND (rb.total_revenue IS NOT NULL OR sd.total_quantity IS NOT NULL)
GROUP BY ch.c_first_name, ch.c_last_name, da.ca_city, da.ca_state, rb.total_revenue
ORDER BY total_sales_quantity DESC, average_net_paid DESC;
