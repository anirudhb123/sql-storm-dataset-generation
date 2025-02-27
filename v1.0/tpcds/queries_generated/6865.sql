
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sold_date_sk,
        ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        w.web_open_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_year = 'Y')
    GROUP BY 
        ws.web_site_sk, ws.ws_sold_date_sk, ws_item_sk
)

SELECT 
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS row_num,
    d.d_date AS sale_date,
    w.web_name AS website,
    i.i_item_id AS item_id,
    i.i_item_desc AS item_description,
    rs.total_quantity,
    rs.total_sales
FROM 
    RankedSales rs
JOIN 
    item i ON rs.ws_item_sk = i.i_item_sk
JOIN 
    date_dim d ON rs.ws_sold_date_sk = d.d_date_sk
JOIN 
    web_site w ON rs.web_site_sk = w.web_site_sk
WHERE 
    rs.sales_rank <= 10
ORDER BY 
    total_sales DESC, sale_date ASC;
