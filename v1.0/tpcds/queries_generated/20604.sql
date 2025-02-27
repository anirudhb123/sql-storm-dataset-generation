
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_sales,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity
    FROM
        web_sales ws
    WHERE
        ws.ws_sales_price IS NOT NULL
),
FilteredSales AS (
    SELECT
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        rs.total_quantity
    FROM
        RankedSales rs
    WHERE
        rs.rank_sales <= 5
),
ForwardReturns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        AVG(sr_return_amt_inc_tax) AS avg_return_amt
    FROM
        store_returns
    GROUP BY
        sr_item_sk
    HAVING
        SUM(sr_return_quantity) > 0
),
SalesWithReturns AS (
    SELECT
        fs.ws_item_sk,
        fs.ws_order_number,
        fs.ws_sales_price,
        COALESCE(fr.total_returns, 0) AS total_returns,
        COALESCE(fr.avg_return_amt, 0) AS avg_return_amt
    FROM
        FilteredSales fs
    LEFT JOIN
        ForwardReturns fr ON fs.ws_item_sk = fr.sr_item_sk
),
FinalSelections AS (
    SELECT
        swr.ws_item_sk,
        swr.ws_order_number,
        swr.ws_sales_price,
        swr.total_returns,
        swr.avg_return_amt,
        CASE
            WHEN swr.total_returns > 0 THEN 'Returned'
            WHEN swr.ws_sales_price < 10 THEN 'Cheap'
            ELSE 'Standard'
        END AS price_category
    FROM
        SalesWithReturns swr
    WHERE
        swr.ws_sales_price > 50 OR (swr.total_returns > 0 AND swr.avg_return_amt IS NOT NULL)
)
SELECT
    fa.ca_city,
    fs.ws_item_sk,
    COUNT(fs.ws_order_number) AS total_orders,
    SUM(fs.ws_sales_price) AS total_sales_value,
    SUM(CASE WHEN fa.price_category = 'Returned' THEN 1 ELSE 0 END) AS returns_count
FROM
    FinalSelections fs
JOIN
    customer_address fa ON fa.ca_address_sk IN (
        SELECT c.c_current_addr_sk
        FROM customer c
        WHERE c.c_customer_sk IN (
            SELECT ws.ws_bill_customer_sk
            FROM web_sales ws
            WHERE ws.ws_sales_price IS NOT NULL
        )
    )
GROUP BY
    fa.ca_city, fs.ws_item_sk
HAVING
    COUNT(fs.ws_order_number) > 5
ORDER BY
    total_sales_value DESC,
    returns_count ASC;
