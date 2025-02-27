
WITH ranked_sales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
        AND w.web_rec_start_date IS NOT NULL
        AND ws.ws_sold_date_sk BETWEEN 20200101 AND 20211231
    GROUP BY 
        ws.web_site_id
), top_sales AS (
    SELECT 
        web_site_id,
        total_sales
    FROM 
        ranked_sales
    WHERE 
        sales_rank <= 5
)
SELECT 
    t.web_site_id,
    t.total_sales,
    s.w_warehouse_id,
    COUNT(e.inv_quantity_on_hand) AS total_inventory
FROM 
    top_sales t
JOIN 
    warehouse s ON t.web_site_id = s.w_warehouse_name
LEFT JOIN 
    inventory e ON s.w_warehouse_sk = e.inv_warehouse_sk
GROUP BY 
    t.web_site_id, t.total_sales, s.w_warehouse_id
ORDER BY 
    t.total_sales DESC;
