
WITH customer_return_stats AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
),
item_sales AS (
    SELECT
        w.web_site_id,
        COUNT(ws.order_number) AS total_sales,
        SUM(ws.net_profit) AS total_sales_profit,
        AVG(ws.net_paid) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY 
        w.web_site_id
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(i.inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT i.i_item_id) AS unique_items
    FROM 
        inventory i
    JOIN 
        warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    crs.c_customer_id,
    crs.total_returns,
    crs.total_return_amount,
    crs.total_return_quantity,
    is.total_sales,
    is.total_sales_profit,
    is.avg_sales_price,
    ws.w_warehouse_id,
    ws.total_inventory,
    ws.unique_items
FROM 
    customer_return_stats crs
JOIN 
    item_sales is ON crs.c_customer_id = (
        SELECT c.c_customer_id 
        FROM customer c
        WHERE c.c_customer_sk = (
            SELECT sr.sr_customer_sk
            FROM store_returns sr
            WHERE sr.sr_return_amt = (
                SELECT MAX(sr2.sr_return_amt)
                FROM store_returns sr2
                WHERE sr2.sr_customer_sk = crs.c_customer_sk
            )
        )
    )
JOIN 
    warehouse_summary ws ON is.web_site_id = (
        SELECT w.web_site_id
        FROM web_site w
        WHERE w.web_warehouse_sk = (
            SELECT MAX(i.inv_warehouse_sk)
            FROM inventory i
            WHERE i.inv_quantity_on_hand > 0
        )
    )
WHERE 
    crs.total_return_amount IS NOT NULL
    AND is.total_sales_profit > 1000
ORDER BY 
    crs.total_return_amount DESC;
