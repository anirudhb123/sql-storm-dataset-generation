
SELECT 
    CONCAT(CAST(CA.ca_street_number AS CHAR), ' ', CA.ca_street_name, ' ', CA.ca_street_type) AS full_address,
    UPPER(CONCAT(CD.cd_gender, ' - ', CD.cd_marital_status)) AS customer_demo,
    SUBSTR(ITEM.i_item_desc, 1, 30) || '...' AS short_item_desc,
    D.d_date AS sales_date,
    SUM(WS.ws_sales_price) AS total_sales,
    COUNT(DISTINCT WS.ws_order_number) AS num_orders
FROM 
    customer_address CA
INNER JOIN 
    customer C ON CA.ca_address_sk = C.c_current_addr_sk
INNER JOIN 
    customer_demographics CD ON C.c_current_cdemo_sk = CD.cd_demo_sk
INNER JOIN 
    web_sales WS ON WS.ws_ship_addr_sk = CA.ca_address_sk
INNER JOIN 
    item ITEM ON WS.ws_item_sk = ITEM.i_item_sk
INNER JOIN 
    date_dim D ON WS.ws_sold_date_sk = D.d_date_sk
WHERE 
    CA.ca_city LIKE '%York%'
    AND CD.cd_purchase_estimate > 1000
GROUP BY 
    full_address, customer_demo, short_item_desc, sales_date
HAVING 
    total_sales > 5000
ORDER BY 
    total_sales DESC;
