
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
        AND ws.ws_sold_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ws.ws_item_sk

    UNION ALL
   
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_quantity,
        COUNT(cr.cr_order_number) AS order_count,
        SUM(cr.cr_return_amount) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cr.cr_item_sk ORDER BY SUM(cr.cr_return_amount) ASC) AS rank
    FROM 
        catalog_returns cr
    JOIN 
        item i ON cr.cr_item_sk = i.i_item_sk
    WHERE 
        cr.cr_returned_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
        AND cr.cr_returned_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        cr.cr_item_sk
),
sales_summary AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(s.total_quantity, 0) AS total_sold,
        COALESCE(r.total_quantity, 0) AS total_returned,
        (COALESCE(s.total_sales, 0) - COALESCE(r.total_sales, 0)) AS net_sales,
        (COALESCE(s.order_count, 0) - COALESCE(r.order_count, 0)) AS net_orders
    FROM 
        item
    LEFT JOIN 
        (SELECT * FROM sales_data WHERE rank = 1) AS s ON item.i_item_sk = s.ws_item_sk
    LEFT JOIN 
        (SELECT * FROM sales_data WHERE rank = 1) AS r ON item.i_item_sk = r.cr_item_sk
)
SELECT 
    ss.i_item_id,
    ss.i_item_desc,
    ss.total_sold,
    ss.total_returned,
    ss.net_sales,
    ss.net_orders,
    CASE 
        WHEN ss.total_sold IS NULL OR ss.total_sold = 0 THEN 'No Sales'
        WHEN ss.net_sales < 0 THEN 'Net Loss'
        ELSE 'Profitable'
    END AS sales_status
FROM 
    sales_summary ss
WHERE 
    ss.net_orders > 10
ORDER BY 
    ss.net_sales DESC
LIMIT 100;
