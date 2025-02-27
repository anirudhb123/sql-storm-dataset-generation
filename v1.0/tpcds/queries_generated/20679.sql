
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales_price,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
),
CustomerReturns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt
    FROM store_returns
    GROUP BY sr_item_sk
),
HighValueCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
    AND cd.cd_credit_rating IS NOT NULL
),
RecentSales AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS recent_sales_price
    FROM web_sales
    WHERE ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = CURRENT_DATE - INTERVAL '30 days')
    GROUP BY ws_sold_date_sk, ws_item_sk
),
SalesWithReturns AS (
    SELECT
        rs.ws_item_sk,
        rs.total_sales_price,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        (rs.total_sales_price - COALESCE(cr.total_return_amt, 0)) AS net_sales
    FROM RankedSales rs
    LEFT JOIN CustomerReturns cr ON rs.ws_item_sk = cr.sr_item_sk
)

SELECT
    swr.ws_item_sk,
    swr.total_sales_price,
    swr.total_returns,
    swr.total_return_amt,
    swr.net_sales,
    COALESCE(r.recent_sales_price, 0) AS recent_sales_price,
    (CASE
        WHEN swr.total_sales_price > 10000 THEN 'High Value'
        WHEN swr.net_sales < 0 THEN 'Refund Dominated'
        ELSE 'Normal'
     END) AS sales_category
FROM SalesWithReturns swr
LEFT JOIN RecentSales r ON swr.ws_item_sk = r.ws_item_sk
WHERE swr.net_sales < (SELECT AVG(net_sales) FROM SalesWithReturns)
ORDER BY swr.net_sales ASC
LIMIT 100
OFFSET (SELECT COUNT(*) FROM SalesWithReturns) / 2;
