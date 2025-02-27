
WITH sales_summary AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN store s ON s.s_store_sk = ws.ws_ship_addr_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
        AND i.i_current_price > 100
    GROUP BY ws.ws_item_sk
),
inventory_status AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_stock
    FROM inventory inv
    WHERE inv.inv_date_sk = (
        SELECT MAX(inv_date_sk) FROM inventory
    )
    GROUP BY inv.inv_item_sk
),
sales_rank AS (
    SELECT
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        ss.order_count,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM sales_summary ss
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    COALESCE(ss.total_quantity, 0) AS total_quantity_sold,
    COALESCE(ss.total_sales, 0) AS total_sales_value,
    COALESCE(is.total_stock, 0) AS current_stock,
    CASE
        WHEN ss.sales_rank <= 10 THEN 'Top Seller'
        ELSE 'Regular'
    END AS sales_category
FROM item i
LEFT JOIN sales_rank ss ON i.i_item_sk = ss.ws_item_sk
LEFT JOIN inventory_status is ON i.i_item_sk = is.inv_item_sk
WHERE 
    (COALESCE(ss.total_sales, 0) > 0 OR COALESCE(is.total_stock, 0) > 0)
ORDER BY total_sales_value DESC;
