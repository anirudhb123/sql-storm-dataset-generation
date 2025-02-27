
WITH RankedSales AS (
    SELECT
        ws.web_site_id,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk 
        FROM date_dim d 
        WHERE d.d_year = 2023 AND d.d_month_seq IN (1, 2, 3) 
    )
), TotalReturns AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_quantity) AS total_return_quantity,
        SUM(wr_return_amt) AS total_return_amt
    FROM web_returns
    GROUP BY wr_item_sk
), TopProducts AS (
    SELECT 
        ir.i_item_id,
        ir.i_item_desc,
        SUM(rs.ws_quantity) AS total_sold_quantity,
        COALESCE(tr.total_return_quantity, 0) AS total_return_quantity,
        (SUM(rs.ws_quantity) - COALESCE(tr.total_return_quantity, 0)) AS net_sales_quantity
    FROM RankedSales rs
    JOIN item ir ON rs.ws_item_sk = ir.i_item_sk
    LEFT JOIN TotalReturns tr ON ir.i_item_sk = tr.wr_item_sk
    GROUP BY ir.i_item_id, ir.i_item_desc
    HAVING net_sales_quantity > 100
)
SELECT 
    tp.i_item_id,
    tp.i_item_desc,
    tp.total_sold_quantity,
    tp.total_return_quantity,
    tp.net_sales_quantity,
    CASE 
        WHEN tp.net_sales_quantity < 0 THEN 'Negative Sales'
        WHEN tp.net_sales_quantity BETWEEN 1 AND 50 THEN 'Low Sales'
        WHEN tp.net_sales_quantity BETWEEN 51 AND 100 THEN 'Moderate Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM TopProducts tp 
ORDER BY tp.net_sales_quantity DESC
LIMIT 10;
