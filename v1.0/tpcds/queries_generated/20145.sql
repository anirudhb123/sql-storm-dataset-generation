
WITH Ranked_Sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS price_rank,
        COALESCE(ws.ws_net_paid, 0) AS net_paid,
        DENSE_RANK() OVER (ORDER BY ws.ws_net_profit DESC) AS profit_rank,
        DATE_PART('year', dd.d_date) AS sales_year
    FROM 
        web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        ws.ws_sales_price > (SELECT AVG(ws2.ws_sales_price) FROM web_sales ws2 WHERE ws2.ws_web_page_sk IS NOT NULL)
),
Top_Orders AS (
    SELECT 
        rs.ws_order_number,
        COUNT(*) AS item_count,
        SUM(rs.net_paid) AS total_paid
    FROM 
        Ranked_Sales rs
    WHERE 
        rs.price_rank <= 3
    GROUP BY rs.ws_order_number
),
Final_Summary AS (
    SELECT 
        to.ws_order_number,
        to.item_count,
        to.total_paid,
        CASE 
            WHEN to.total_paid IS NULL THEN 'No Sales'
            WHEN to.total_paid > 1000 THEN 'High Value'
            ELSE 'Low Value'
        END AS order_value_category,
        1.0 / NULLIF(to.item_count, 0) AS avg_price_per_item
    FROM 
        Top_Orders to
)
SELECT 
    fs.ws_order_number,
    fs.item_count,
    fs.total_paid,
    fs.order_value_category,
    fs.avg_price_per_item,
    w.w_warehouse_name,
    COALESCE(w.w_gmt_offset, 0) AS warehouse_offset
FROM 
    Final_Summary fs
LEFT JOIN warehouse w ON w.w_warehouse_sk = (SELECT DISTINCT ws.ws_warehouse_sk FROM web_sales ws WHERE ws.ws_order_number = fs.ws_order_number LIMIT 1)
WHERE 
    fs.total_paid IS NOT NULL
    AND fs.total_paid > (SELECT AVG(total_paid) FROM Final_Summary WHERE order_value_category = 'High Value')
ORDER BY 
    fs.total_paid DESC, fs.item_count ASC
LIMIT 10;
