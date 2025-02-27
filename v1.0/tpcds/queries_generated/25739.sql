
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_income_band_sk,
        a.ca_city,
        a.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
),
item_info AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_category,
        i.i_brand
    FROM 
        item i
),
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_ext_sales_price) AS total_revenue
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
    HAVING 
        total_sales > 100
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ii.i_item_desc,
    ii.i_category,
    ii.i_brand,
    sd.total_sales,
    sd.total_revenue
FROM 
    customer_info ci
JOIN 
    sales_data sd ON ci.c_customer_sk = sd.ws_item_sk
JOIN 
    item_info ii ON sd.ws_item_sk = ii.i_item_sk
WHERE 
    ci.cd_gender = 'F' 
    AND ci.ca_state IN ('CA', 'NY') 
ORDER BY 
    sd.total_revenue DESC
LIMIT 50;
