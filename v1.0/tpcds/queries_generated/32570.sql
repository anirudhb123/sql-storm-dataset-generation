
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_order_number,
        ws_sold_date_sk,
        ws_ship_mode_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_paid,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
        
    UNION ALL
    
    SELECT 
        cs_order_number,
        cs_sold_date_sk,
        cs_ship_mode_sk,
        cs_item_sk,
        cs_quantity,
        cs_net_paid,
        level + 1
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk IN (SELECT ws_sold_date_sk FROM web_sales)
        AND cs_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales))
)

SELECT 
    c.c_customer_id,
    MAX(sd.date) AS last_return_date,
    COUNT(DISTINCT sr_ticket_number) AS total_returns,
    SUM(sr_return_amt_inc_tax) AS total_return_value,
    SUM(ws.net_paid) AS total_sales_value,
    SUM(ir.inv_quantity_on_hand) AS inv_quantity_hand
FROM 
    customer c
LEFT JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk 
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
LEFT JOIN 
    (SELECT DISTINCT 
         sr_return_date_sk,
         sr_return_time_sk, 
         sr_item_sk
     FROM 
         store_returns) sr_items ON sr.sr_item_sk = sr_items.sr_item_sk
LEFT JOIN 
    inventory ir ON ws.ws_item_sk = ir.inv_item_sk 
LEFT JOIN 
    (SELECT 
         d.d_date_sk,
         d.d_date,
         d.d_year
     FROM 
         date_dim d) sd ON sr.sr_returned_date_sk = sd.d_date_sk
WHERE 
    c.c_birth_year < 1970 
    AND (sr_return_date_sk IS NOT NULL OR ws_sold_date_sk IS NOT NULL)
GROUP BY 
    c.c_customer_id
HAVING 
    total_returns > 0
ORDER BY 
    total_sales_value DESC;
