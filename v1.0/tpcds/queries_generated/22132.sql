
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20000101 AND 20001231
),
cumulative_returns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        COUNT(DISTINCT sr_ticket_number) AS total_return_entries
    FROM 
        store_returns 
    GROUP BY 
        sr_item_sk
),
item_summary AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(CAST(cs_total.total_sales AS decimal(10, 2)), 0) AS total_sales,
        COALESCE(CAST(cr_total.total_returned AS decimal(10, 2)), 0) AS total_returns,
        i.i_current_price
    FROM 
        item i
    LEFT JOIN (
        SELECT 
            cs.cs_item_sk,
            SUM(cs.cs_ext_sales_price) AS total_sales
        FROM 
            catalog_sales cs
        GROUP BY 
            cs.cs_item_sk
    ) cs_total ON i.i_item_sk = cs_total.cs_item_sk
    LEFT JOIN cumulative_returns cr_total ON i.i_item_sk = cr_total.sr_item_sk
),
 -- Lateral Join Test
top_items AS (
    SELECT 
        is_summary.i_item_sk,
        is_summary.i_item_desc,
        is_summary.total_sales,
        is_summary.total_returns,
        (is_summary.total_sales - is_summary.total_returns * is_summary.i_current_price) AS net_gain_loss,
        (SELECT COUNT(*) FROM ranked_sales WHERE rank_sales = 1 AND ws_item_sk = is_summary.i_item_sk) AS highest_rank
    FROM 
        item_summary is_summary
)
SELECT 
    ti.i_item_sk,
    ti.i_item_desc,
    ti.total_sales,
    ti.total_returns,
    ti.net_gain_loss,
    CASE 
        WHEN ti.highest_rank > 0 THEN 'Top Item'
        WHEN ti.total_sales > 1000 THEN 'High Seller'
        ELSE 'Regular Item'
    END AS item_category,
    (CASE 
        WHEN ti.net_gain_loss IS NULL THEN 'Loss'
        WHEN ti.net_gain_loss < 0 THEN 'Loss'
        ELSE 'Profit'
    END) AS profit_loss_status
FROM 
    top_items ti
WHERE 
    ti.net_gain_loss IS NOT NULL 
    AND EXISTS (
        SELECT 1 
        FROM store s
        WHERE s.s_store_sk IN (
            SELECT sr_store_sk FROM store_returns sr WHERE sr_item_sk = ti.i_item_sk
        ) 
        AND s.s_state = 'CA'
    )
ORDER BY 
    ti.net_gain_loss DESC NULLS LAST
LIMIT 100;
