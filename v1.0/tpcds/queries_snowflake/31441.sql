
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price
    FROM web_sales
    WHERE ws_sold_date_sk > (
        SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01'
    )
    UNION ALL
    SELECT 
        cs_item_sk,
        cs_order_number,
        cs_quantity,
        cs_sales_price
    FROM catalog_sales cs
    JOIN sales_cte s ON cs_item_sk = s.ws_item_sk
    WHERE cs_sold_date_sk > (
        SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01'
    )
),
ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) as rn
    FROM sales_cte
),
gross_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        SUM(ws_quantity) AS total_quantity
    FROM web_sales
    GROUP BY ws_item_sk
),
returns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_amt) AS total_returns
    FROM web_returns
    GROUP BY wr_item_sk
),
final_sales AS (
    SELECT 
        s.ws_item_sk,
        gs.total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        (gs.total_sales - COALESCE(r.total_returns, 0)) AS net_sales,
        ROW_NUMBER() OVER (ORDER BY (gs.total_sales - COALESCE(r.total_returns, 0)) DESC) AS sales_rank
    FROM gross_sales gs
    LEFT JOIN returns r ON gs.ws_item_sk = r.wr_item_sk
    JOIN ranked_sales s ON gs.ws_item_sk = s.ws_item_sk
)
SELECT 
    f.ws_item_sk,
    f.total_sales,
    f.total_returns,
    f.net_sales,
    f.sales_rank,
    (SELECT COUNT(*) FROM final_sales WHERE net_sales > f.net_sales) AS rank_position
FROM final_sales f
WHERE f.net_sales > 1000
ORDER BY f.sales_rank;
