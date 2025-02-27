
WITH sold_items AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 1 AND 1000
    GROUP BY ws_item_sk
),
returns AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt) AS total_returned_amt
    FROM web_returns
    GROUP BY wr_item_sk
),
inventory_data AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory
    WHERE inv_date_sk = 1
    GROUP BY inv_item_sk
),
qualified_sales AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(si.total_sold, 0) AS total_sold,
        COALESCE(rt.total_returns, 0) AS total_returns,
        COALESCE(it.total_inventory, 0) AS total_inventory,
        (COALESCE(si.total_sold, 0) - COALESCE(rt.total_returns, 0)) AS net_sales
    FROM item i
    LEFT JOIN sold_items si ON i.i_item_sk = si.ws_item_sk
    LEFT JOIN returns rt ON i.i_item_sk = rt.wr_item_sk
    LEFT JOIN inventory_data it ON i.i_item_sk = it.inv_item_sk
),
ranked_sales AS (
    SELECT
        qs.i_item_sk,
        qs.i_item_desc,
        qs.total_sold,
        qs.total_returns,
        qs.total_inventory,
        qs.net_sales,
        DENSE_RANK() OVER (ORDER BY qs.net_sales DESC) AS sales_rank
    FROM qualified_sales qs
    WHERE qs.total_inventory > 0
      AND qs.net_sales IS NOT NULL
      AND qs.total_sold > 10
)
SELECT
    r.sales_rank,
    r.i_item_sk,
    r.i_item_desc,
    r.total_sold,
    r.total_returns,
    r.total_inventory,
    CASE 
        WHEN r.net_sales < 0 THEN 'Significant Returns'
        WHEN r.net_sales <= 100 THEN 'Low Sales'
        WHEN r.net_sales BETWEEN 101 AND 1000 THEN 'Moderate Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM ranked_sales r
WHERE r.sales_rank <= 10
ORDER BY r.sales_rank
UNION ALL
SELECT
    NULL AS sales_rank,
    i.i_item_sk,
    i.i_item_desc,
    0 AS total_sold,
    0 AS total_returns,
    0 AS total_inventory,
    'Not Sold' AS sales_category
FROM item i
WHERE i.i_item_sk NOT IN (SELECT i_item_sk FROM ranked_sales)
ORDER BY sales_category, i_item_sk;
