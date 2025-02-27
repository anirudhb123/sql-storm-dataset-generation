
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS rn,
        CASE 
            WHEN ws.ws_ext_sales_price IS NULL THEN 'N/A'
            ELSE CAST(ws.ws_ext_sales_price AS VARCHAR(20)) 
        END AS formatted_sales_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
high_value_sales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        NVL(SUM(ws.ws_ext_sales_price), 0) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_ext_sales_price) AS max_sales_price
    FROM 
        item
    LEFT JOIN 
        web_sales ws ON item.i_item_sk = ws.ws_item_sk
    WHERE 
        ws.ws_ext_sales_price > 500 OR ws.ws_item_sk IS NULL
    GROUP BY 
        item.i_item_id, item.i_item_desc
    HAVING 
        total_sales > 10000
),
refund_analysis AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_refunds,
        COUNT(DISTINCT cr.cr_order_number) AS refund_orders
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_return_amount > 0
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    item.i_item_id,
    item.i_item_desc,
    sales.total_sales,
    sales.order_count,
    COALESCE(refunds.total_refunds, 0) AS total_refunds,
    refunds.refund_orders,
    CASE 
        WHEN refunds.refund_orders > 0 THEN 'Has Refunds'
        ELSE 'No Refunds'
    END AS refund_status,
    RANK() OVER (ORDER BY sales.total_sales DESC) AS sales_rank,
    (SELECT COUNT(*) FROM high_value_sales) AS high_value_items
FROM 
    high_value_sales sales
LEFT JOIN 
    refund_analysis refunds ON sales.i_item_id = refunds.cr_item_sk
ORDER BY 
    sales_rank
FETCH FIRST 100 ROWS ONLY;
