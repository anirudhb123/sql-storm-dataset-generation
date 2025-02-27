
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
item_info AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_product_name,
        i.i_current_price
    FROM 
        item i
),
sales_data AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales_price
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_date_sk, ws.ws_item_sk
),
sales_summary AS (
    SELECT 
        di.d_year,
        di.d_month_seq,
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ii.i_item_id,
        ii.i_product_name,
        sd.total_quantity,
        sd.total_sales_price
    FROM 
        sales_data sd
    JOIN 
        date_dim di ON sd.ws_ship_date_sk = di.d_date_sk
    JOIN 
        item_info ii ON sd.ws_item_sk = ii.i_item_sk
    JOIN 
        customer_info ci ON ci.c_customer_sk = sd.ws_item_sk % 1000  -- Simulating customer mapping based on item_sk for demonstration
)
SELECT 
    s.y,
    COUNT(DISTINCT s.full_name) AS unique_customers,
    SUM(s.total_quantity) AS total_units_sold,
    ROUND(SUM(s.total_sales_price), 2) AS total_sales,
    STRING_AGG(DISTINCT CONCAT(s.ca_city, ', ', s.ca_state), '; ') AS cities_involved
FROM 
    sales_summary s
GROUP BY 
    s.y
ORDER BY 
    s.y DESC
LIMIT 10;
