
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        i.i_branded AS brand,
        i.i_color,
        i.i_size,
        i.i_item_desc
    FROM 
        item i
    WHERE 
        LENGTH(i.i_item_desc) > 50
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        ss.ss_ext_sales_price,
        ss.ss_net_profit
    FROM 
        web_sales ws
    FULL OUTER JOIN 
        catalog_sales cs ON ws.ws_order_number = cs.cs_order_number
    FULL OUTER JOIN 
        store_sales ss ON ws.ws_order_number = ss.ss_ticket_number
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    id.brand,
    id.i_product_name,
    SUM(sd.ws_ext_sales_price) AS total_web_sales,
    SUM(sd.cs_ext_sales_price) AS total_catalog_sales,
    SUM(sd.ss_ext_sales_price) AS total_store_sales,
    COUNT(DISTINCT sd.ws_order_number) AS total_orders_web,
    COUNT(DISTINCT sd.cs_order_number) AS total_orders_catalog,
    COUNT(DISTINCT sd.ss_ticket_number) AS total_orders_store
FROM 
    CustomerInfo ci
JOIN 
    ItemDetails id ON ci.c_customer_sk = id.i_item_sk
JOIN 
    SalesData sd ON sd.ws_order_number IS NOT NULL 
OR sd.cs_order_number IS NOT NULL 
OR sd.ss_ticket_number IS NOT NULL
GROUP BY 
    ci.full_name, ci.ca_city, ci.ca_state, ci.ca_country, id.brand, id.i_product_name
HAVING 
    total_web_sales > 1000 AND total_catalog_sales > 500 AND total_store_sales > 1500
ORDER BY 
    ci.ca_city, total_web_sales DESC, total_catalog_sales DESC;
