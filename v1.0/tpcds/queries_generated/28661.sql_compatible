
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_buy_potential AS marital_buy_pattern,
        cd.cd_education_status AS education_level
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
LatestOrders AS (
    SELECT 
        ws.ws_ship_customer_sk,
        ws.ws_order_number,
        MAX(d.d_date) AS latest_order_date
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.ws_ship_customer_sk, 
        ws.ws_order_number
),
OrderDetails AS (
    SELECT 
        lo.ws_order_number,
        lo.latest_order_date,
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        ci.marital_buy_pattern
    FROM 
        LatestOrders lo
    JOIN 
        CustomerInfo ci ON lo.ws_ship_customer_sk = ci.c_customer_id
)
SELECT 
    o.ws_order_number,
    o.latest_order_date,
    o.full_name,
    o.ca_city,
    o.ca_state,
    o.cd_gender,
    o.marital_buy_pattern,
    COUNT(DISTINCT i.i_item_id) AS unique_items_ordered,
    SUM(ws.ws_sales_price) AS total_spent
FROM 
    OrderDetails o
JOIN 
    web_sales ws ON o.ws_order_number = ws.ws_order_number
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
GROUP BY 
    o.ws_order_number, 
    o.latest_order_date,
    o.full_name,
    o.ca_city,
    o.ca_state,
    o.cd_gender,
    o.marital_buy_pattern
ORDER BY 
    o.latest_order_date DESC;
