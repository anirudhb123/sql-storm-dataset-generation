
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) as rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 1000
), total_sales AS (
    SELECT 
        item.i_item_id,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        item ON ws.ws_item_sk = item.i_item_sk
    WHERE 
        ws.ws_sold_date_sk >= 1
    GROUP BY 
        item.i_item_id
), returns_info AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(wr.wr_order_number) AS total_returns
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk IS NOT NULL
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    i.i_item_id,
    ts.total_sales_amount,
    COALESCE(ri.total_return_amount, 0) AS total_return_amount,
    (ts.total_sales_amount - COALESCE(ri.total_return_amount, 0)) AS net_sales,
    COUNT(DISTINCT r.rank) AS number_of_top_sales
FROM 
    total_sales ts
LEFT JOIN 
    ranked_sales r ON ts.i_item_id = r.ws_item_sk AND r.rank <= 5
LEFT JOIN 
    item i ON ts.i_item_id = i.i_item_id
LEFT JOIN 
    returns_info ri ON i.i_item_sk = ri.wr_item_sk
WHERE 
    i.i_current_price IS NOT NULL
AND 
    (COALESCE(ri.total_returns, 0) <= 10 OR ri.total_returns IS NULL)
GROUP BY 
    i.i_item_id, ts.total_sales_amount, ri.total_return_amount
ORDER BY 
    net_sales DESC
LIMIT 100;
