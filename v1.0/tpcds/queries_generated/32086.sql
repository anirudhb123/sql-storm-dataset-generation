
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.web_site_sk, 
        ws.web_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) 
                               FROM date_dim 
                               WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_sk, ws.web_name
),
top_sales AS (
    SELECT 
        web_site_sk, 
        web_name, 
        total_sales, 
        order_count
    FROM sales_summary
    WHERE sales_rank <= 5
),
return_stats AS (
    SELECT 
        COALESCE(sr.sr_item_sk, cr.cr_item_sk) AS item_sk,
        SUM(COALESCE(sr.sr_return_quantity, 0) + COALESCE(cr.cr_return_quantity, 0)) AS total_returns,
        SUM(COALESCE(sr.sr_return_amt, 0) + COALESCE(cr.cr_return_amount, 0)) AS total_return_value
    FROM 
        store_returns sr
    FULL OUTER JOIN 
        catalog_returns cr ON sr.sr_item_sk = cr.cr_item_sk
    GROUP BY 
        COALESCE(sr.sr_item_sk, cr.cr_item_sk)
),
high_return_items AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        rs.total_returns,
        rs.total_return_value
    FROM 
        return_stats rs
    JOIN 
        item i ON i.i_item_sk = rs.item_sk
    WHERE 
        rs.total_return_value > (SELECT AVG(total_return_value) FROM return_stats)
),
aggregated_data AS (
    SELECT 
        ts.web_name,
        COUNT(DISTINCT hri.i_item_id) AS unique_return_items,
        SUM(hri.total_returns) AS total_return_items,
        SUM(hri.total_return_value) AS total_return_value
    FROM 
        top_sales ts
    JOIN 
        high_return_items hri ON ts.web_site_sk = hri.item_sk
    GROUP BY 
        ts.web_name
)
SELECT 
    ad.web_name,
    ad.unique_return_items,
    ad.total_return_items,
    ad.total_return_value,
    CONCAT('Total Returns for ', ad.web_name, ': ', ad.total_return_items) AS return_info
FROM 
    aggregated_data ad
ORDER BY 
    ad.total_return_value DESC;
