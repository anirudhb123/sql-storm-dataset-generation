
WITH Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
Item_Info AS (
    SELECT 
        i.i_item_sk,
        UPPER(i.i_product_name) AS product_name,
        LENGTH(i.i_item_desc) AS description_length,
        i.i_current_price
    FROM 
        item i
),
Sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.cd_gender,
    ci.cd_marital_status,
    ii.product_name,
    ii.description_length,
    COALESCE(s.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(s.total_profit, 0) AS total_profit
FROM 
    Customer_Info ci
JOIN 
    Item_Info ii ON ii.i_item_sk = (SELECT ws_item_sk FROM web_sales ORDER BY RANDOM() LIMIT 1)
LEFT JOIN 
    Sales s ON ii.i_item_sk = s.ws_item_sk
WHERE 
    ci.cd_gender = 'F' AND 
    ci.cd_marital_status = 'M'
ORDER BY 
    ci.full_name, 
    ii.product_name
LIMIT 100;
