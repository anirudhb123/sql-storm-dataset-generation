
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) 
                             FROM date_dim 
                             WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid) AS total_sales
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk >= (SELECT MAX(d_date_sk) 
                             FROM date_dim 
                             WHERE d_year = 2023)
    GROUP BY 
        cs_sold_date_sk, cs_item_sk
),
item_performance AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc, 
        COALESCE(SUM(sd.total_quantity), 0) AS total_quantity, 
        COALESCE(SUM(sd.total_sales), 0) AS total_sales,
        RANK() OVER (ORDER BY COALESCE(SUM(sd.total_sales), 0) DESC) AS sales_rank
    FROM 
        item i
    LEFT JOIN 
        sales_data sd ON i.i_item_sk = sd.ws_item_sk OR i.i_item_sk = sd.cs_item_sk
    GROUP BY 
        i.i_item_id, i.i_item_desc
),
top_items AS (
    SELECT 
        item_id,
        item_desc,
        total_quantity,
        total_sales,
        sales_rank
    FROM 
        item_performance
    WHERE 
        sales_rank <= 10
)
SELECT 
    ti.item_id,
    ti.item_desc,
    ti.total_quantity,
    ti.total_sales,
    ROUND(ti.total_sales / NULLIF(ti.total_quantity, 0), 2) AS avg_price,
    CASE 
        WHEN ti.total_sales > 10000 THEN 'High Performer'
        WHEN ti.total_sales BETWEEN 5000 AND 10000 THEN 'Mid Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    top_items ti
ORDER BY 
    ti.total_sales DESC;
