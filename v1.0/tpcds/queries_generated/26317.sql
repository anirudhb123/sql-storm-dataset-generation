
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
item_info AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        i.i_brand,
        i.i_current_price,
        i.i_category
    FROM 
        item i
    WHERE 
        i.i_current_price > 50.00
        AND i.i_category IN (SELECT DISTINCT i_category FROM item WHERE i_current_price < 20.00)
),
sale_stats AS (
    SELECT 
        ws.ws_bill_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2459922 AND 2459954 
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.ca_zip,
    i.i_item_id,
    i.i_item_desc,
    i.i_brand,
    i.i_current_price,
    ss.total_orders,
    ss.total_sales,
    ss.total_profit
FROM 
    customer_info ci
JOIN 
    sale_stats ss ON ci.c_customer_id = ss.ws_bill_customer_sk
JOIN 
    item_info i ON EXISTS (
        SELECT 1 
        FROM web_sales ws
        WHERE ws.ws_bill_customer_sk = ss.ws_bill_customer_sk 
        AND ws.ws_item_sk = i.i_item_sk
    )
ORDER BY 
    ss.total_sales DESC,
    ci.full_name ASC
LIMIT 100;
