
WITH customer_data AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE cd.cd_gender = 'F' AND ca.ca_state = 'CA'
),
sales_data AS (
    SELECT
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk > (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY ws.ws_ship_date_sk, ws.ws_item_sk
),
item_data AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        i.i_category,
        i.i_brand,
        i.i_current_price
    FROM item i
)

SELECT
    cd.full_name,
    cd.ca_city,
    cd.ca_state,
    cd.ca_country,
    SUM(sd.total_quantity_sold) AS total_quantity,
    LISTAGG(CONCAT(id.i_item_desc, ' (', id.i_brand, ': $', id.i_current_price, ')'), ', ') AS items_purchased
FROM customer_data cd
JOIN sales_data sd ON cd.c_customer_sk = sd.ws_item_sk
JOIN item_data id ON sd.ws_item_sk = id.i_item_sk
GROUP BY cd.full_name, cd.ca_city, cd.ca_state, cd.ca_country
ORDER BY total_quantity DESC
LIMIT 10;
