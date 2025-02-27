
WITH ReturnStats AS (
    SELECT 
        COALESCE(SUM(sr_return_quantity), 0) AS total_return_quantity,
        COUNT(DISTINCT sr_returned_date_sk) AS return_days,
        MAX(sr_return_amt_inc_tax) AS max_return_amt
    FROM store_returns
    WHERE sr_returned_date_sk IS NOT NULL
),
SalesStats AS (
    SELECT 
        SUM(ws_quantity) AS total_sales_quantity,
        AVG(ws_sales_price) AS avg_sales_price,
        MAX(ws_net_profit) AS max_net_profit,
        d.d_year AS sales_year
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        RANK() OVER (ORDER BY SUM(ws.ws_quantity) DESC) AS item_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY i.i_item_id, i.i_product_name
    HAVING SUM(ws.ws_quantity) > 100
)
SELECT 
    tt.i_item_id,
    tt.i_product_name,
    ss.total_sales_quantity,
    ss.avg_sales_price,
    ss.max_net_profit,
    rs.total_return_quantity,
    rs.return_days,
    rs.max_return_amt
FROM TopItems tt
CROSS JOIN SalesStats ss
CROSS JOIN ReturnStats rs
WHERE EXISTS (
    SELECT 1
    FROM web_sales ws
    WHERE ws.ws_item_sk = tt.i_item_id
      AND ws.ws_ship_date_sk = (
          SELECT MAX(ws_ship_date_sk) 
          FROM web_sales 
          WHERE ws_item_sk = tt.i_item_id
            AND ws_ship_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = ss.sales_year) - 365 
            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = ss.sales_year)
      )
)
ORDER BY ss.total_sales_quantity DESC, rs.total_return_quantity DESC;
