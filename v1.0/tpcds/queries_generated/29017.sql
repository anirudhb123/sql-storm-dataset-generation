
WITH CustomerData AS (
    SELECT 
        c.c_customer_id AS customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        cd.cd_education_status AS education,
        ca.ca_city AS city,
        ca.ca_state AS state,
        ca.ca_country AS country,
        ca.ca_zip AS zip_code,
        cd.cd_purchase_estimate AS purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'M' AND 
        cd.cd_marital_status = 'M' AND 
        cd.cd_purchase_estimate > 1000
),
ItemData AS (
    SELECT 
        i.i_item_id AS item_id,
        i.i_item_desc AS item_description,
        i.i_current_price AS price,
        i.i_brand AS brand,
        i.i_category AS category
    FROM 
        item i
    WHERE 
        i.i_current_price < 50
),
SalesData AS (
    SELECT 
        ws.ws_order_number AS order_number,
        ws.ws_ship_date_sk AS ship_date,
        ws.ws_quantity AS quantity,
        ws.ws_sales_price AS sales_price,
        ws.ws_net_profit AS net_profit,
        ws.ws_item_sk AS item_sk
    FROM 
        web_sales ws
    UNION ALL
    SELECT 
        cs.cs_order_number AS order_number,
        cs.cs_ship_date_sk AS ship_date,
        cs.cs_quantity AS quantity,
        cs.cs_sales_price AS sales_price,
        cs.cs_net_profit AS net_profit,
        cs.cs_item_sk AS item_sk
    FROM 
        catalog_sales cs
),
CombinedData AS (
    SELECT 
        cd.customer_id,
        cd.full_name,
        cd.city,
        cd.state,
        cd.country,
        cd.zip_code,
        id.item_id,
        id.item_description,
        id.price,
        sd.order_number,
        sd.ship_date,
        sd.quantity,
        sd.sales_price,
        sd.net_profit
    FROM 
        CustomerData cd
    JOIN 
        SalesData sd ON sd.order_number IS NOT NULL
    JOIN 
        ItemData id ON sd.item_sk = id.item_id
)
SELECT 
    customer_id,
    full_name,
    city,
    state,
    country,
    zip_code,
    item_id,
    item_description,
    SUM(quantity) AS total_quantity,
    SUM(sales_price) AS total_sales,
    SUM(net_profit) AS total_net_profit
FROM 
    CombinedData
GROUP BY 
    customer_id, full_name, city, state, country, zip_code, item_id, item_description
ORDER BY 
    total_net_profit DESC
LIMIT 100;
