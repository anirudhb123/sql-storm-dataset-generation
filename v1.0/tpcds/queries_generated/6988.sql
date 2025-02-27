
WITH ranked_sales AS (
    SELECT 
        s_store_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY s_store_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    JOIN 
        store ON web_sales.ws_ship_addr_sk = store.s_addr_sk
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                             AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023 AND d_moy = 12)
    GROUP BY 
        s_store_sk, 
        ws_item_sk
), top_sales AS (
    SELECT 
        s_store_sk,
        ws_item_sk,
        total_sales
    FROM 
        ranked_sales
    WHERE 
        sales_rank <= 5
), item_details AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price,
        i_brand,
        i_category
    FROM 
        item
), detailed_sales AS (
    SELECT 
        ts.s_store_sk,
        ts.ws_item_sk,
        ts.total_sales,
        id.i_item_desc,
        id.i_current_price,
        id.i_brand,
        id.i_category
    FROM 
        top_sales ts
    JOIN 
        item_details id ON ts.ws_item_sk = id.i_item_sk
)
SELECT 
    ds.s_store_sk,
    ds.total_sales,
    ds.i_item_desc,
    ds.i_current_price,
    ds.i_brand,
    ds.i_category,
    AVG(ds.total_sales) OVER (PARTITION BY ds.i_category) AS avg_category_sales,
    COUNT(ds.i_item_desc) OVER (PARTITION BY ds.i_category) AS item_count
FROM 
    detailed_sales ds
ORDER BY 
    ds.s_store_sk, 
    ds.total_sales DESC;
