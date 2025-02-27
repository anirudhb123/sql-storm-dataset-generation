
WITH customer_details AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ad.ca_city,
        ad.ca_state,
        ad.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ad ON c.c_current_addr_sk = ad.ca_address_sk
), 
item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        customer_details cd ON ws.ws_bill_customer_sk = cd.c_customer_id
    GROUP BY 
        ws.ws_item_sk
), 
top_items AS (
    SELECT 
        is.ws_item_sk,
        im.i_item_id,
        im.i_item_desc,
        im.i_category,
        im.i_current_price,
        is.total_quantity,
        is.total_net_profit
    FROM 
        item_sales is
    JOIN 
        item im ON is.ws_item_sk = im.i_item_sk
    ORDER BY 
        is.total_net_profit DESC
    LIMIT 10
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    ti.i_category,
    ti.i_current_price,
    ti.total_quantity,
    ti.total_net_profit,
    COUNT(DISTINCT cd.c_customer_id) AS unique_customers
FROM 
    top_items ti
JOIN 
    web_sales ws ON ti.ws_item_sk = ws.ws_item_sk
JOIN 
    customer_details cd ON ws.ws_bill_customer_sk = cd.c_customer_id
GROUP BY 
    ti.i_item_id, ti.i_item_desc, ti.i_category, ti.i_current_price, ti.total_quantity, ti.total_net_profit
ORDER BY 
    ti.total_net_profit DESC;
