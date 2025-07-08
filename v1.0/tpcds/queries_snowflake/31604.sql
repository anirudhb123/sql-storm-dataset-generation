
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity_sold, 
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
top_sales AS (
    SELECT 
        ws_item_sk,
        SUM(total_quantity_sold) AS total_quantity,
        SUM(total_sales) AS total_sales_amount
    FROM 
        sales_summary
    WHERE 
        rank <= 10
    GROUP BY 
        ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    t.total_quantity,
    t.total_sales_amount,
    COALESCE(NULLIF(cd.cd_gender, ''), 'Not Specified') AS gender,
    COALESCE(NULLIF(cd.cd_marital_status, ''), 'Unknown') AS marital_status,
    da.d_date AS sales_date,
    ROW_NUMBER() OVER (PARTITION BY i.i_item_sk ORDER BY t.total_sales_amount DESC) AS sales_rank
FROM 
    item i
JOIN 
    top_sales t ON i.i_item_sk = t.ws_item_sk
JOIN 
    date_dim da ON da.d_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales WHERE ws_item_sk = t.ws_item_sk)
LEFT JOIN 
    customer c ON c.c_current_cdemo_sk = i.i_item_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    t.total_quantity > 100
    AND t.total_sales_amount > 5000
    AND da.d_year = 2023
ORDER BY 
    t.total_sales_amount DESC;
