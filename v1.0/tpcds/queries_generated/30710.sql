
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                           AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
), 
top_sales AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        sd.total_quantity,
        sd.total_sales,
        CTE_rank.rank
    FROM 
        sales_data sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    JOIN 
        (SELECT DISTINCT total_quantity, total_sales FROM sales_data WHERE rank <= 5) AS CTE_rank
        ON sd.total_sales = CTE_rank.total_sales
)
SELECT 
    t_rank.i_item_id,
    t_rank.i_item_desc,
    t_rank.total_quantity,
    t_rank.total_sales,
    CASE 
        WHEN t_rank.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status,
    COALESCE(ROUND(AVG(t_rank.total_sales) OVER (PARTITION BY t_rank.i_item_id), 2), 0) AS avg_sales,
    (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_item_sk = t_rank.ws_item_sk) AS store_count
FROM 
    top_sales t_rank
LEFT JOIN 
    store s ON s.s_store_sk = (SELECT s_store_sk FROM store_sales WHERE ss_item_sk = t_rank.ws_item_sk ORDER BY ss_net_paid DESC LIMIT 1)
ORDER BY 
    t_rank.total_sales DESC;
