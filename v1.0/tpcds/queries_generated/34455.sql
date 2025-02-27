
WITH RECURSIVE ItemHierarchy AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_id, 
        i.i_item_desc, 
        i.i_current_price, 
        1 AS level 
    FROM 
        item i 
    WHERE 
        i.i_item_sk IS NOT NULL
    
    UNION ALL
    
    SELECT 
        i.i_item_sk, 
        i.i_item_id, 
        CONCAT(ih.i_item_desc, ' -> ', i.i_item_desc), 
        i.i_current_price, 
        ih.level + 1 
    FROM 
        ItemHierarchy ih 
    JOIN 
        item i ON ih.i_item_sk = i.i_item_sk 
    WHERE 
        ih.level < 5
), 
SalesData AS (
    SELECT 
        ws.ws_order_number, 
        ws.ws_item_sk, 
        ws.ws_sales_price, 
        COALESCE(sr.sr_return_amt, 0) AS total_returns, 
        (ws.ws_sales_price - COALESCE(sr.sr_return_amt, 0)) AS net_sales 
    FROM 
        web_sales ws 
    LEFT JOIN 
        store_returns sr ON ws.ws_order_number = sr.sr_ticket_number AND ws.ws_item_sk = sr.sr_item_sk 
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231
), 
CustomerStats AS (
    SELECT 
        c.c_customer_id, 
        COUNT(DISTINCT ws.ws_order_number) AS total_orders, 
        SUM(ws.ws_quantity) AS total_items_ordered, 
        SUM(ws.ws_sales_price) AS total_spent 
    FROM 
        customer c 
    JOIN 
        SalesData sd ON sd.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    ch.i_item_id,
    ch.i_item_desc,
    ch.i_current_price,
    COALESCE(cs.total_orders, 0) AS total_orders,
    COALESCE(cs.total_items_ordered, 0) AS total_items_ordered,
    COALESCE(cs.total_spent, 0) AS total_spent,
    RANK() OVER (PARTITION BY ch.level ORDER BY COALESCE(cs.total_spent, 0) DESC) AS rank
FROM 
    ItemHierarchy ch 
LEFT JOIN 
    CustomerStats cs ON ch.i_item_sk = cs.total_orders
WHERE 
    ch.i_current_price > (
        SELECT 
            AVG(i_current_price) 
        FROM 
            item 
        WHERE 
            i_brand = 'BrandA'
    ) 
ORDER BY 
    total_spent DESC 
LIMIT 100;
