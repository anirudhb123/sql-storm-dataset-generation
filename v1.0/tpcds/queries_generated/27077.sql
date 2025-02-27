
WITH CustomerCity AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        STRING_AGG(CONCAT(c_first_name, ' ', c_last_name), '; ') AS customer_names
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca_city
),
ItemSales AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_net_paid) AS total_sales,
        STRING_AGG(DISTINCT CONCAT(i.i_item_desc, ' ($', i.i_current_price, ')'), ', ') AS item_details
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id
)
SELECT 
    c.ca_city,
    c.customer_count,
    c.customer_names,
    i.total_sales,
    i.item_details
FROM 
    CustomerCity c
LEFT JOIN 
    ItemSales i ON i.total_sales > 1000
ORDER BY 
    c.customer_count DESC, i.total_sales DESC;
