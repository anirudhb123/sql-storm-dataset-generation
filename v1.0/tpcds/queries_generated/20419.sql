
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_paid DESC) AS rn
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > 0
),
CustomerReturns AS (
    SELECT
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt_inc_tax) AS total_returned_amount
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
SalesWithReturns AS (
    SELECT
        rs.web_site_sk,
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_quantity,
        rs.ws_net_paid,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(cr.total_returned_amount, 0) AS total_returned_amount
    FROM RankedSales rs
    LEFT JOIN CustomerReturns cr ON rs.ws_order_number = cr.wr_returning_customer_sk
)
SELECT
    swr.web_site_sk,
    SUM(swr.ws_net_paid) AS total_sales,
    SUM(swr.total_returned_amount) AS total_returns,
    COUNT(DISTINCT swr.ws_order_number) AS total_orders,
    ROUND(SUM(swr.ws_net_paid) - SUM(swr.total_returned_amount), 2) AS net_revenue,
    COUNT(CASE WHEN swr.total_returned_quantity > 0 THEN 1 END) AS total_returned_orders,
    MAX(CASE WHEN swr.total_returned_quantity > 0 THEN swr.ws_quantity END) AS max_returned_order_quantity,
    MIN(CASE WHEN swr.total_returned_quantity > 0 THEN swr.ws_quantity END) AS min_returned_order_quantity
FROM SalesWithReturns swr
WHERE swr.ws_quantity > 0
GROUP BY swr.web_site_sk
HAVING net_revenue > 1000 AND COUNT(swr.ws_order_number) > 5
ORDER BY total_sales DESC, total_returns ASC
LIMIT 10;
