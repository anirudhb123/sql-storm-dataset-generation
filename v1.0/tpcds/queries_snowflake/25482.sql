
WITH CustomerDetails AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        c.c_customer_sk
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        i.i_category,
        i.i_item_sk
    FROM 
        item i
    WHERE 
        LOWER(i.i_item_desc) LIKE '%organic%'
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        cd.customer_name,
        cd.ca_city,
        cd.ca_state,
        cd.c_customer_sk
    FROM 
        web_sales ws
    JOIN 
        CustomerDetails cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
    WHERE 
        ws.ws_sales_price > 100
)
SELECT 
    sd.customer_name,
    sd.ca_city,
    sd.ca_state,
    SUM(sd.ws_sales_price * sd.ws_quantity) AS total_spent,
    COUNT(DISTINCT sd.ws_order_number) AS total_orders,
    LISTAGG(DISTINCT CONCAT(id.i_item_id, ': ', id.i_item_desc), '; ') WITHIN GROUP (ORDER BY id.i_item_id) AS purchased_items
FROM 
    SalesData sd
JOIN 
    ItemDetails id ON sd.ws_order_number IN (
        SELECT cs_order_number FROM catalog_sales WHERE cs_item_sk = id.i_item_sk
        UNION 
        SELECT ss_ticket_number FROM store_sales WHERE ss_item_sk = id.i_item_sk
    )
GROUP BY 
    sd.customer_name, 
    sd.ca_city, 
    sd.ca_state,
    sd.c_customer_sk
ORDER BY 
    total_spent DESC
LIMIT 10;
