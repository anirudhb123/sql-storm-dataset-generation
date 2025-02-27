
WITH sales_summary AS (
    SELECT 
        cs.item_sk,
        SUM(cs.net_paid_inc_tax) AS total_sales,
        SUM(cs.net_profit) AS total_profit,
        COUNT(DISTINCT cs.order_number) AS order_count
    FROM 
        catalog_sales cs
    JOIN 
        item i ON cs.item_sk = i.item_sk
    JOIN 
        date_dim d ON cs.sold_date_sk = d.date_sk
    WHERE 
        d.year = 2022 AND 
        i.category_id IN (SELECT DISTINCT category_id FROM item WHERE brand = 'BrandA')
    GROUP BY 
        cs.item_sk
), customer_engagement AS (
    SELECT 
        c.customer_sk,
        COUNT(DISTINCT ws.order_number) AS web_order_count,
        COUNT(DISTINCT ss.ticket_number) AS store_order_count,
        MAX(ws.sold_date_sk) AS last_web_order_date,
        MAX(ss.sold_date_sk) AS last_store_order_date
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.customer_sk = ws.bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.customer_sk = ss.customer_sk
    GROUP BY 
        c.customer_sk
), inventory_summary AS (
    SELECT 
        inv.item_sk,
        SUM(inv.quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    JOIN 
        warehouse w ON inv.warehouse_sk = w.warehouse_sk
    WHERE 
        w.state = 'CA'
    GROUP BY 
        inv.item_sk
)
SELECT 
    ce.customer_sk,
    ss.total_sales,
    ss.total_profit,
    ce.web_order_count,
    ce.store_order_count,
    ce.last_web_order_date,
    ce.last_store_order_date,
    is.total_inventory
FROM 
    customer_engagement ce
LEFT JOIN 
    sales_summary ss ON ce.customer_sk = ss.item_sk
LEFT JOIN 
    inventory_summary is ON ss.item_sk = is.item_sk
WHERE 
    ss.total_sales > 1000
ORDER BY 
    total_profit DESC;
