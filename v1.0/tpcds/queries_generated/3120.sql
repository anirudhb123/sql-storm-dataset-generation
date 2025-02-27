
WITH ranked_sales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2022-01-01')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2022-12-31')
    GROUP BY
        ws_item_sk
),
related_items AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        COALESCE(inv.inv_quantity_on_hand, 0) AS quantity_on_hand
    FROM
        item i
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    WHERE
        i.i_rec_start_date <= CURRENT_DATE
        AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURRENT_DATE)
),
top_selling_items AS (
    SELECT
        r.ws_item_sk,
        r.total_quantity,
        r.total_sales,
        ROW_NUMBER() OVER (ORDER BY r.total_sales DESC) AS top_rank
    FROM
        ranked_sales r
    WHERE
        r.sales_rank = 1
)
SELECT
    tsi.ws_item_sk,
    ri.i_item_id,
    ri.i_product_name,
    ri.i_brand,
    ts.total_sales,
    ts.total_quantity,
    ri.quantity_on_hand,
    (CASE
        WHEN ri.quantity_on_hand < 10 THEN 'Low Stock'
        WHEN ri.quantity_on_hand BETWEEN 10 AND 50 THEN 'In Stock'
        ELSE 'High Stock'
    END) AS stock_status
FROM
    top_selling_items ts
JOIN
    related_items ri ON ts.ws_item_sk = ri.i_item_sk
WHERE
    ri.quantity_on_hand IS NOT NULL
    AND ts.total_sales > (SELECT AVG(total_sales) FROM top_selling_items)
ORDER BY
    ts.total_sales DESC
LIMIT 100
