
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales 
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    HAVING 
        SUM(ws_quantity) > 50
),
InventoryCTE AS (
    SELECT 
        i.inv_item_sk,
        SUM(i.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory i
    GROUP BY 
        i.inv_item_sk
),
CustomerCTE AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_income_band_sk,
        SUM(CASE WHEN ws.ws_sold_date_sk IS NOT NULL THEN 1 ELSE 0 END) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_income_band_sk
)
SELECT 
    ca.ca_city,
    CA.total_sales,
    COALESCE(SUM(s.total_quantity), 0) AS total_quantity,
    COALESCE(i.total_inventory, 0) AS total_inventory,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    AVG(CASE WHEN ca.ca_state IS NULL THEN NULL ELSE 1 END) AS is_state_null 
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    CustomerCTE CA ON c.c_customer_sk = CA.c_customer_sk
LEFT JOIN 
    SalesCTE s ON c.c_customer_sk = s.ws_item_sk
LEFT JOIN 
    InventoryCTE i ON s.ws_item_sk = i.inv_item_sk
WHERE 
    (ca.ca_city LIKE '%New%' OR ca.ca_city LIKE '%Town%')
    AND (i.total_inventory > 0 OR i.total_inventory IS NULL)
GROUP BY 
    ca.ca_city, CA.total_sales, i.total_inventory
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 10
ORDER BY 
    total_quantity DESC, ca.ca_city
LIMIT 100;
