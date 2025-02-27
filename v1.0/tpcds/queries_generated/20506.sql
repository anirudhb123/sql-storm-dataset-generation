
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_ship_date_sk,
        ws_quantity,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
top_sales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(SUM(r.ws_ext_sales_price), 0) AS total_sales_price,
        COALESCE(SUM(r.ws_quantity), 0) AS total_quantity,
        COUNT(r.ws_order_number) AS total_orders
    FROM 
        item
    LEFT JOIN 
        ranked_sales r ON item.i_item_sk = r.ws_item_sk 
    WHERE 
        r.rn = 1
    GROUP BY 
        item.i_item_id, item.i_item_desc
),
high_demand_items AS (
    SELECT 
        ts.i_item_id,
        ts.i_item_desc,
        ts.total_sales_price,
        ts.total_quantity,
        ts.total_orders,
        ROW_NUMBER() OVER (ORDER BY ts.total_sales_price DESC) AS top_item_rank
    FROM 
        top_sales ts
    WHERE 
        ts.total_quantity > 0
        AND ts.total_sales_price IS NOT NULL
)
SELECT 
    hdi.i_item_id, 
    hdi.i_item_desc, 
    hdi.total_sales_price, 
    hdi.total_quantity,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
    SUM(CASE WHEN item.i_brand = 'BrandX' THEN 1 ELSE 0 END) AS brandx_purchases
FROM 
    high_demand_items hdi
LEFT JOIN 
    web_sales ws ON hdi.i_item_id = ws.ws_item_sk
LEFT JOIN 
    item ON hdi.i_item_id = item.i_item_id
WHERE 
    hdi.top_item_rank <= 10
    AND (ws.ws_ship_date_sk IS NOT NULL OR ws.ws_order_number IS NOT NULL)
GROUP BY 
    hdi.i_item_id, hdi.i_item_desc, hdi.total_sales_price, hdi.total_quantity
HAVING 
    AVG(hdi.total_sales_price) > (SELECT AVG(ws_ext_sales_price) FROM web_sales)
ORDER BY 
    hdi.total_quantity DESC;
