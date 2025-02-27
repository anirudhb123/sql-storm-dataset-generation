
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        COALESCE(cr.cr_return_quantity, 0) AS total_returns,
        COALESCE(sr.sr_return_quantity, 0) AS total_store_returns,
        SUM(ws.ws_sales_price * ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS latest_sales
    FROM 
        web_sales ws
    LEFT JOIN 
        catalog_returns cr ON ws.ws_item_sk = cr.cr_item_sk AND ws.ws_order_number = cr.cr_order_number
    LEFT JOIN 
        store_returns sr ON ws.ws_item_sk = sr.sr_item_sk AND ws.ws_order_number = sr.sr_ticket_number
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(sd.total_sales) AS total_sales,
    SUM(sd.total_returns) AS total_returns,
    AVG(sd.ws_sales_price) AS avg_sales_price,
    COUNT(DISTINCT sd.ws_item_sk) AS unique_items_sold
FROM 
    SalesData sd
JOIN 
    customer c ON sd.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    sd.latest_sales = 1
    AND sd.total_sales > 0
    AND ca.ca_state IS NOT NULL
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    SUM(sd.total_sales) > 10000
ORDER BY 
    total_sales DESC, ca.ca_state;
