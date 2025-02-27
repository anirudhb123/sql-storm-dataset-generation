
WITH sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND ws_sold_date_sk <= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
top_items AS (
    SELECT 
        s.ws_item_sk,
        i.i_item_id,
        i.i_item_desc,
        ss.total_quantity,
        ss.total_sales,
        ss.total_orders,
        DENSE_RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        sales_summary ss
    JOIN 
        item i ON ss.ws_item_sk = i.i_item_sk
    JOIN 
        store s ON i.i_item_sk = s.s_store_sk
)
SELECT 
    ti.sales_rank,
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    ti.total_orders
FROM 
    top_items ti
WHERE 
    ti.sales_rank <= 10
ORDER BY 
    ti.total_sales DESC;
