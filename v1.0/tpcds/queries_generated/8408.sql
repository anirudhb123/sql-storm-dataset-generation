
WITH sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_web_page_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk, ws_web_page_sk
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        hd.hd_income_band_sk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
item_data AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_category,
        i.i_brand
    FROM item i
),
summary AS (
    SELECT 
        c.ca_city,
        c.ca_state,
        i.i_item_desc,
        i.i_brand,
        s.ws_sold_date_sk,
        SUM(s.total_quantity) AS total_sold,
        SUM(s.total_net_profit) AS total_profit
    FROM sales_data s
    JOIN customer_data c ON s.ws_item_sk = c.c_customer_sk  
    JOIN item_data i ON s.ws_item_sk = i.i_item_sk
    GROUP BY c.ca_city, c.ca_state, i.i_item_desc, i.i_brand, s.ws_sold_date_sk
)
SELECT 
    city,
    state,
    item_desc,
    brand,
    DATE_FORMAT(FROM_UNIXTIME(ws_sold_date_sk), '%Y-%m-%d') AS sold_date,
    total_sold,
    total_profit
FROM summary
WHERE total_profit > 1000
ORDER BY total_profit DESC, total_sold DESC
LIMIT 100;
