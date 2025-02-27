
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws_order_number,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
        AND ws.ws_sold_date_sk IN (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_month_seq BETWEEN 1 AND 12
            AND d_year = 2023
        )
    GROUP BY 
        ws.web_site_sk, 
        ws_order_number
),
top_sales AS (
    SELECT 
        web_site_sk,
        ws_order_number,
        total_sales
    FROM 
        ranked_sales
    WHERE
        sales_rank <= 10
),
inventory_status AS (
    SELECT 
        inv.inv_item_sk,
        SUM(CASE 
            WHEN inv.inv_quantity_on_hand = 0 THEN 1 
            ELSE 0 
        END) AS out_of_stock_count,
        SUM(CASE 
            WHEN inv.inv_quantity_on_hand > 0 THEN inv.inv_quantity_on_hand 
            ELSE NULL 
        END) AS total_available
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    ts.web_site_sk,
    ts.ws_order_number,
    ts.total_sales,
    COUNT(DISTINCT i.inv_item_sk) AS distinct_items_sold,
    COALESCE(i.out_of_stock_count, 0) AS total_items_out_of_stock,
    COALESCE(i.total_available, 0) AS total_items_available,
    CASE 
        WHEN i.out_of_stock_count IS NOT NULL THEN 'Some items out of stock' 
        ELSE 'All items available' 
    END AS stock_status
FROM 
    top_sales ts
LEFT JOIN 
    inventory_status i ON i.inv_item_sk IN (
        SELECT ws.ws_item_sk
        FROM web_sales ws
        WHERE ws.ws_order_number = ts.ws_order_number
    )
GROUP BY 
    ts.web_site_sk, ts.ws_order_number, ts.total_sales, i.out_of_stock_count, i.total_available
ORDER BY 
    ts.total_sales DESC;
