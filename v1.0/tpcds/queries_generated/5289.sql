
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        i.i_category,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS average_profit
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.web_site_id, i.i_category
),
top_categories AS (
    SELECT 
        web_site_id,
        i_category,
        total_quantity,
        total_sales,
        average_profit,
        ROW_NUMBER() OVER (PARTITION BY web_site_id ORDER BY total_sales DESC) AS rnk
    FROM 
        sales_summary
)
SELECT 
    w.web_site_name,
    t.web_site_id,
    t.i_category,
    t.total_quantity,
    t.total_sales,
    t.average_profit
FROM 
    top_categories t
JOIN 
    web_site w ON t.web_site_id = w.web_site_id
WHERE 
    t.rnk <= 5
ORDER BY 
    w.web_site_name, t.total_sales DESC;
