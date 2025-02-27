
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        ws.order_number, 
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > 0 AND ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
    GROUP BY ws.web_site_sk, ws.order_number, ws_sold_date_sk
),
CumulativeReturns AS (
    SELECT 
        wr.returning_customer_sk, 
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt) AS total_return_amount
    FROM web_returns wr
    GROUP BY wr.returning_customer_sk
),
SalesReturnSummary AS (
    SELECT 
        r.web_site_sk,
        SUM(r.total_sales) AS total_sales,
        COALESCE(rs.total_returned, 0) as total_returned,
        COALESCE(rs.total_return_amount, 0) as total_return_amount,
        CASE 
            WHEN COALESCE(rs.total_returned, 0) = 0 THEN 0
            ELSE SUM(r.total_sales) / COALESCE(rs.total_returned, 1)
        END AS sales_to_return_ratio
    FROM RankedSales r
    LEFT JOIN CumulativeReturns rs ON r.order_number = rs.returning_customer_sk
    GROUP BY r.web_site_sk
)
SELECT 
    w.w_warehouse_name,
    srs.total_sales,
    srs.total_returned,
    srs.total_return_amount,
    srs.sales_to_return_ratio
FROM SalesReturnSummary srs
JOIN warehouse w ON srs.web_site_sk = w.w_warehouse_sk
ORDER BY srs.sales_to_return_ratio DESC
LIMIT 10;
