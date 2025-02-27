
WITH CustomerItems AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ARRAY_AGG(DISTINCT CONCAT(i.i_item_desc, ' (', i.i_current_price, ')')) AS purchased_items
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, ca.ca_country
),
SalesDetails AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        COUNT(ws.ws_item_sk) AS total_items,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_order_number, ws.ws_sold_date_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    ci.purchased_items,
    sd.total_items,
    sd.total_sales
FROM 
    CustomerItems ci
JOIN 
    SalesDetails sd ON ci.c_customer_id = (SELECT c.c_customer_id FROM customer c JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk WHERE ws.ws_order_number = sd.ws_order_number LIMIT 1)
WHERE 
    ci.ca_state = 'CA'
ORDER BY 
    sd.total_sales DESC
LIMIT 10;
