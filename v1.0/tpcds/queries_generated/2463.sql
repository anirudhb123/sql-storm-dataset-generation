
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity_sold
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2023 AND d.d_month_seq = 6
        LIMIT 1
    ) AND (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2023 AND d.d_month_seq = 8
        LIMIT 1
    )
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(rs.total_quantity_sold, 0) AS total_quantity,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    AVG(rs.ws_sales_price) AS avg_sales_price
FROM item i
LEFT JOIN RankedSales rs ON i.i_item_sk = rs.ws_item_sk AND rs.price_rank = 1
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
WHERE i.i_category_id IN (
        SELECT DISTINCT ca_category_id
        FROM catalog_page cp
        WHERE cp.cp_department = 'Electronics'
    )
AND (i.i_current_price > 10 OR i.i_current_price IS NULL)
GROUP BY i.i_item_id, i.i_item_desc
HAVING order_count > 5
ORDER BY total_quantity DESC, avg_sales_price ASC
LIMIT 100;
