
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rnk
    FROM 
        web_sales
),
InventoryCTE AS (
    SELECT 
        inv_date_sk,
        inv_item_sk,
        inv_quantity_on_hand,
        ROW_NUMBER() OVER (PARTITION BY inv_item_sk ORDER BY inv_date_sk DESC) AS rnk
    FROM 
        inventory
),
CustomerCTE AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        (cd_dep_count + COALESCE(cd_dep_employed_count, 0)) AS family_size
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE 
        cd_gender = 'F'
)
SELECT 
    ca.city AS address_city,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales_amount,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    COUNT(DISTINCT i.inv_item_sk) AS total_unique_items_in_inventory
FROM 
    web_sales ws
LEFT JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    SalesCTE scte ON ws.ws_item_sk = scte.ws_item_sk AND scte.rnk = 1
LEFT JOIN 
    InventoryCTE icte ON ws.ws_item_sk = icte.inv_item_sk AND icte.rnk = 1
WHERE 
    ws.ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales WHERE ws_sold_date_sk IS NOT NULL)
GROUP BY 
    ca.city
HAVING 
    SUM(ws.ws_quantity) > 100
ORDER BY 
    total_sales_amount DESC
LIMIT 10;
