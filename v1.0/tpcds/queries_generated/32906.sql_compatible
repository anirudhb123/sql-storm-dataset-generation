
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.sold_date_sk, 
        ws.item_sk, 
        SUM(ws.quantity) AS total_quantity, 
        SUM(ws.net_paid) AS total_revenue
    FROM 
        web_sales ws
    GROUP BY 
        ws.sold_date_sk, ws.item_sk

    UNION ALL

    SELECT 
        cs.sold_date_sk, 
        cs.item_sk, 
        SUM(cs.quantity) + ss.total_quantity AS total_quantity, 
        SUM(cs.net_paid_inc_tax) + ss.total_revenue AS total_revenue
    FROM 
        catalog_sales cs
    JOIN 
        sales_summary ss ON cs.sold_date_sk = ss.sold_date_sk AND cs.item_sk = ss.item_sk
    GROUP BY 
        cs.sold_date_sk, cs.item_sk, ss.total_quantity, ss.total_revenue
)
SELECT 
    d.d_date AS sale_date,
    i.i_item_id,
    COALESCE(ss.total_quantity, 0) AS total_quantity,
    COALESCE(ss.total_revenue, 0) AS total_revenue,
    CASE 
        WHEN ss.total_quantity IS NULL THEN 'No Sales'
        ELSE 'Sales Made'
    END AS sales_status,
    COUNT(DISTINCT ws.ws_order_number) AS order_count
FROM 
    date_dim d
LEFT JOIN 
    sales_summary ss ON d.d_date_sk = ss.sold_date_sk
LEFT JOIN 
    item i ON ss.item_sk = i.i_item_sk
LEFT JOIN 
    web_sales ws ON ss.item_sk = ws.ws_item_sk AND d.d_date_sk = ws.ws_sold_date_sk
WHERE 
    d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    d.d_date, i.i_item_id, ss.total_quantity, ss.total_revenue
ORDER BY 
    d.d_date, total_revenue DESC;
