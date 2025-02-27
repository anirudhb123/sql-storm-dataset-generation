
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        CASE 
            WHEN ws.ws_sales_price IS NULL THEN 'No Price'
            WHEN ws.ws_sales_price = 0 THEN 'Free'
            ELSE 'Paid'
        END AS price_status
    FROM 
        web_sales ws
    LEFT JOIN 
        item it ON ws.ws_item_sk = it.i_item_sk
    WHERE 
        it.i_current_price IS NOT NULL
),
high_value_sales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        rs.price_status
    FROM 
        ranked_sales rs
    WHERE 
        rs.price_rank = 1
),
average_store_sales AS (
    SELECT 
        ss.s_store_sk,
        AVG(ss.ss_net_paid) AS avg_net_sales
    FROM 
        store_sales ss
    GROUP BY 
        ss.s_store_sk
),
return_summary AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns,
        SUM(cr.cr_return_amount) AS total_returned_amount
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_item_sk IN (SELECT h.ws_item_sk FROM high_value_sales h)
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    it.i_item_id,
    COALESCE(avs.avg_net_sales, 0) AS store_avg_sales,
    COALESCE(hv.total_returns, 0) AS item_total_returns,
    COALESCE(hv.total_returned_amount, 0.00) AS item_total_returned_amount,
    hv.price_status
FROM 
    item it
LEFT JOIN 
    average_store_sales avs ON it.i_item_sk = avs.s_store_sk
LEFT JOIN 
    return_summary hv ON it.i_item_sk = hv.cr_item_sk
WHERE 
    it.i_category = 'Electronics' AND 
    (it.i_manufact IS NOT NULL OR it.i_brand IS NOT NULL)
ORDER BY 
    item_total_returned_amount DESC NULLS LAST
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
