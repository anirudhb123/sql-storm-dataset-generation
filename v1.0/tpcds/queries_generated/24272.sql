
WITH RECURSIVE sales_trend AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank_sales
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
high_value_items AS (
    SELECT 
        i_item_sk,
        i_item_id,
        i_current_price,
        ROW_NUMBER() OVER (ORDER BY i_current_price DESC) AS item_rank
    FROM 
        item 
    WHERE 
        i_current_price IS NOT NULL AND i_current_price > 100.00
),
item_return_stats AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returned,
        AVG(cr_return_amount) AS avg_return_amt
    FROM 
        catalog_returns 
    GROUP BY 
        cr_item_sk
),
outer_joined_data AS (
    SELECT 
        i.i_item_id, 
        s.total_sales, 
        h.total_returned, 
        h.avg_return_amt
    FROM 
        high_value_items h 
    LEFT JOIN 
        sales_trend s 
    ON 
        h.i_item_sk = s.ws_item_sk
    LEFT JOIN 
        item_return_stats h 
    ON 
        h.i_item_sk = h.cr_item_sk
)
SELECT 
    o.i_item_id,
    COALESCE(o.total_sales, 0) AS sales,
    COALESCE(o.total_returned, 0) AS returns,
    COALESCE(o.avg_return_amt, 0) AS avg_return
FROM 
    outer_joined_data o
WHERE 
    (o.sales > 1000 OR o.returns > 10) 
    AND o.i_item_id NOT IN (SELECT i_item_id FROM item WHERE i_rec_end_date < CURRENT_DATE)
ORDER BY 
    o.sales DESC, o.returns ASC
FETCH FIRST 10 ROWS ONLY;
