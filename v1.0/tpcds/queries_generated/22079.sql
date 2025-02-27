
WITH ranked_sales AS (
    SELECT
        ws_item_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid_inc_tax) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
high_value_items AS (
    SELECT
        item.i_item_id,
        item.i_item_desc,
        CASE 
            WHEN COUNT(DISTINCT ws_order_number) > 0 THEN 'Online'
            ELSE 'In-store'
        END AS sales_channel,
        COALESCE(AVG(ws_ext_discount_amt), 0) AS avg_discount
    FROM
        item
    LEFT JOIN web_sales ON item.i_item_sk = web_sales.ws_item_sk
    LEFT JOIN store_sales ON item.i_item_sk = store_sales.ss_item_sk
    WHERE
        (item.i_current_price > (SELECT AVG(i_current_price) FROM item) OR 
         item.i_item_desc LIKE '%special%' OR 
         item.i_item_desc IS NULL)
    GROUP BY
        item.i_item_id, item.i_item_desc
),
top_items AS (
    SELECT
        hvi.i_item_id,
        hvi.i_item_desc,
        hvi.sales_channel,
        hvi.avg_discount,
        RANK() OVER (ORDER BY hvi.avg_discount DESC) AS discount_rank
    FROM
        high_value_items hvi
)
SELECT
    rs.ws_item_sk,
    rs.total_orders,
    rs.total_revenue,
    ti.i_item_id,
    ti.i_item_desc,
    ti.sales_channel,
    ti.avg_discount
FROM
    ranked_sales rs
JOIN
    top_items ti ON rs.ws_item_sk = ti.i_item_id
WHERE
    rs.total_orders > 10 
    AND (ti.avg_discount IS NOT NULL OR ti.sales_channel = 'In-store')
    AND ti.discount_rank <= 5
ORDER BY
    rs.total_revenue DESC, ti.avg_discount ASC;
