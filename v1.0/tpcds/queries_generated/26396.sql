
WITH CustomerLocation AS (
    SELECT c.c_customer_id, ca.ca_city, ca.ca_state
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ItemDescription AS (
    SELECT i.i_item_id, i.i_item_desc, 
           LENGTH(i.i_item_desc) AS description_length,
           TRIM(i.i_item_desc) AS trimmed_description,
           UPPER(i.i_item_desc) AS upper_description
    FROM item i
),
SalesData AS (
    SELECT ws.ws_order_number, ws.ws_item_sk, ws.ws_sales_price,
           ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rank
    FROM web_sales ws
    WHERE ws.ws_sales_price > 0
)
SELECT cl.c_customer_id, cl.ca_city, cl.ca_state,
       id.i_item_id, id.trimmed_description, id.upper_description,
       sd.ws_order_number, sd.ws_sales_price
FROM CustomerLocation cl
JOIN ItemDescription id ON id.i_item_id IN (SELECT ws_item_sk FROM SalesData sd WHERE sd.rank <= 10)
JOIN SalesData sd ON sd.ws_item_sk = id.i_item_id
WHERE cl.ca_state IN ('CA', 'TX')
ORDER BY cl.c_customer_id, sd.ws_sales_price DESC;
