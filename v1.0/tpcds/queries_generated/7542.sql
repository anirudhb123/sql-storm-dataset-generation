
WITH SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        SUM(ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws_order_number) AS order_count,
        w_city,
        w_state,
        d_year
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ws_item_sk, w_city, w_state, d.year
),
TopItems AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_sales,
        ss.total_quantity,
        ss.order_count,
        DENSE_RANK() OVER (PARTITION BY ss.w_city, ss.w_state ORDER BY ss.total_sales DESC) AS sales_rank
    FROM SalesSummary ss
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ti.total_sales,
    ti.total_quantity,
    ti.order_count,
    w.w_city,
    w.w_state
FROM TopItems ti
JOIN item i ON ti.ws_item_sk = i.i_item_sk
JOIN warehouse w ON ti.w_city = w.w_city AND ti.w_state = w.w_state
WHERE ti.sales_rank <= 10
ORDER BY w.w_city, w.w_state, ti.total_sales DESC;
