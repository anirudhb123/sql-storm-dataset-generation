
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > (
            SELECT AVG(i2.i_current_price) 
            FROM item i2 
            WHERE i2.i_category = 'Electronics'
        )
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),
returns_summary AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned,
        COUNT(DISTINCT cr.cr_order_number) AS return_count
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
sales_with_returns AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_sales,
        COALESCE(rs.total_sales - r.total_returned, rs.total_sales) AS net_sales
    FROM 
        ranked_sales rs
    LEFT JOIN 
        returns_summary r ON rs.ws_item_sk = r.cr_item_sk
)
SELECT 
    i.i_item_id,
    swr.total_sales,
    swr.net_sales,
    CASE 
        WHEN swr.net_sales < 0 THEN 'Negative Sales'
        WHEN swr.net_sales = 0 THEN 'No Sales'
        ELSE 'Positive Sales'
    END AS sales_status,
    DENSE_RANK() OVER (ORDER BY swr.net_sales DESC) AS sales_rank
FROM 
    sales_with_returns swr
JOIN 
    item i ON swr.ws_item_sk = i.i_item_sk
WHERE 
    EXISTS (
        SELECT 1 FROM customer c 
        WHERE c.c_customer_sk IN (
            SELECT sr_customer_sk FROM store_returns 
            WHERE sr_item_sk = swr.ws_item_sk AND sr_return_quantity > 0
        )
    )
UNION ALL
SELECT 
    'UNKNOWN ITEM' AS i_item_id,
    NULL AS total_sales,
    NULL AS net_sales,
    'No Data' AS sales_status,
    NULL AS sales_rank
WHERE 
    NOT EXISTS (
        SELECT * FROM sales_with_returns 
    )
ORDER BY 
    sales_rank NULLS LAST, 
    sales_status DESC;
