
WITH RECURSIVE category_hierarchy AS (
    SELECT 
        i_category_id,
        i_category,
        0 AS level
    FROM 
        item
    WHERE 
        i_item_sk IS NOT NULL
    UNION ALL
    SELECT 
        i_category_id,
        CONCAT(ch.i_category, ' > ', i_category),
        ch.level + 1
    FROM 
        category_hierarchy ch
    JOIN 
        item i ON i.category_id = ch.i_category_id
    WHERE 
        ch.level < 3
),
sales_totals AS (
    SELECT 
        ws.web_site_id, 
        ws.web_name, 
        SUM(ws.ws_ext_sales_price) AS total_sales, 
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    INNER JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 100 AND 200
    GROUP BY 
        ws.web_site_id, ws.web_name
),
inventory_summary AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    w.web_name, 
    ch.i_category, 
    st.total_sales, 
    st.order_count, 
    COALESCE(iv.total_quantity, 0) AS total_inventory,
    CASE 
        WHEN st.total_sales IS NULL THEN 'No Sales'
        WHEN st.order_count = 0 THEN 'No Orders'
        ELSE 'Sales Available'
    END AS sales_status,
    ROW_NUMBER() OVER (PARTITION BY ch.i_category ORDER BY st.total_sales DESC) AS rank
FROM 
    sales_totals st
JOIN 
    category_hierarchy ch ON st.web_site_id = ch.i_category_id
LEFT JOIN 
    inventory_summary iv ON iv.inv_item_sk = ch.i_category_id
WHERE 
    iv.total_quantity IS NULL OR iv.total_quantity > 100
ORDER BY 
    ch.i_category, rank;
