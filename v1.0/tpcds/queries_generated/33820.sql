
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        ws_item_sk
),
top_items AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        i.i_product_name,
        i.i_brand,
        i.i_category
    FROM 
        sales_summary ss
    JOIN 
        item i ON ss.ws_item_sk = i.i_item_sk
    WHERE 
        ss.rank <= 10
)
SELECT 
    ti.ws_item_sk,
    ti.i_product_name,
    ti.i_brand,
    ti.i_category,
    ti.total_quantity,
    ti.total_sales,
    COALESCE((
        SELECT 
            ROUND(AVG(ss.total_sales), 2)
        FROM 
            sales_summary ss
        WHERE 
            ss.ws_item_sk <> ti.ws_item_sk
    ), 0) AS average_sales_other_products,
    (ti.total_sales - COALESCE((
        SELECT 
            SUM(COALESCE(wr_return_amt, 0))
        FROM 
            web_returns wr
        WHERE 
            wr.wr_item_sk = ti.ws_item_sk
    ), 0)) AS net_sales
FROM 
    top_items ti
LEFT JOIN 
    store s ON s.s_store_sk = (SELECT MIN(sr_store_sk) FROM store_returns sr WHERE sr.sr_item_sk = ti.ws_item_sk)
WHERE 
    s.s_country IS NULL OR s.s_country <> 'USA' 
ORDER BY 
    ti.total_sales DESC;
