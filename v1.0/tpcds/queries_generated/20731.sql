
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(sr_return_quantity, 0)) AS total_returned_quantity,
        COUNT(DISTINCT sr_ticket_number) AS total_returns
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        COUNT(cs.cs_order_number) AS order_count,
        SUM(COALESCE(ws.ws_quantity, 0)) AS online_sales
    FROM 
        item i
    LEFT JOIN 
        catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id, i.i_product_name, i.i_current_price
),
ReturningCustomers AS (
    SELECT 
        cr.c_customer_sk,
        cr.total_returned_quantity,
        id.i_item_id
    FROM 
        CustomerReturns cr
    JOIN 
        store_sales ss ON cr.c_customer_sk = ss.ss_customer_sk
    JOIN 
        ItemDetails id ON ss.ss_item_sk = id.i_item_sk
    WHERE 
        cr.total_returns > 0 
        AND id.order_count > 10
)
SELECT 
    rc.c_customer_sk,
    rc.total_returned_quantity,
    id.i_item_id,
    id.i_product_name,
    ship.sm_type,
    ROW_NUMBER() OVER (PARTITION BY rc.c_customer_sk ORDER BY rc.total_returned_quantity DESC) AS return_rank
FROM 
    ReturningCustomers rc
JOIN 
    ship_mode ship ON rc.i_item_id LIKE '%' || ship.sm_ship_mode_id || '%'
WHERE 
    id.online_sales > 50
    AND (id.i_current_price IS NOT NULL AND id.i_current_price > 10.00)
ORDER BY 
    rc.total_returned_quantity DESC, 
    return_rank
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
