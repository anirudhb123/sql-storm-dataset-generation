
WITH RECURSIVE sales_data AS (
    SELECT ws_item_sk,
           SUM(ws_quantity) AS total_quantity,
           SUM(ws_sales_price) AS total_sales,
           DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
), customer_summary AS (
    SELECT c_customer_sk,
           COUNT(DISTINCT ws_order_number) AS order_count,
           MAX(ws_net_paid) AS max_net_paid,
           AVG(ws_net_paid) AS avg_net_paid,
           MIN(ws_net_paid) AS min_net_paid
    FROM web_sales ws
    JOIN customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    GROUP BY c_customer_sk
), address_count AS (
    SELECT ca_state,
           COUNT(DISTINCT c_current_addr_sk) AS unique_addresses
    FROM customer
    JOIN customer_address ON c_current_addr_sk = ca_address_sk
    GROUP BY ca_state
)

SELECT cc.cc_name,
       sd.total_quantity,
       sd.total_sales,
       cs.order_count,
       cs.max_net_paid,
       cs.avg_net_paid,
       ac.unique_addresses
FROM sales_data sd
JOIN customer_summary cs ON sd.ws_item_sk = cs.c_customer_sk
JOIN call_center cc ON cc.cc_call_center_sk = (SELECT MAX(cc_call_center_sk) FROM call_center)
LEFT JOIN address_count ac ON A.ca_state = (SELECT ca_state FROM customer_address WHERE ca_address_sk = cs.c_current_addr_sk)
WHERE sd.total_quantity > 10
AND (cs.order_count IS NULL OR cs.order_count > 5)
ORDER BY sd.total_sales DESC
FETCH FIRST 100 ROWS ONLY;
