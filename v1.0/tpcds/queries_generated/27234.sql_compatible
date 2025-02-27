
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
item_info AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_brand,
        i.i_category,
        i.i_current_price
    FROM 
        item i
),
sales_info AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN 2459395 AND 2459450 
    GROUP BY 
        ws.ws_item_sk
),
detailed_info AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        si.total_quantity,
        si.total_sales,
        ii.i_item_desc,
        ii.i_brand,
        ii.i_current_price
    FROM 
        customer_info ci
    JOIN 
        sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
    JOIN 
        item_info ii ON si.ws_item_sk = ii.i_item_sk
)
SELECT 
    full_name,
    cd_gender,
    total_quantity,
    total_sales,
    i_item_desc,
    i_brand,
    i_current_price,
    ROUND(total_sales / NULLIF(total_quantity, 0), 2) AS average_price_per_unit
FROM 
    detailed_info
WHERE 
    cd_gender = 'F'
ORDER BY 
    total_sales DESC
LIMIT 10;
