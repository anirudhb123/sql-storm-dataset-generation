
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) AS rn
    FROM
        web_sales
),
ReturnedItems AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned
    FROM
        web_returns
    GROUP BY
        wr_item_sk
),
HighValueReturns AS (
    SELECT
        r.ws_item_sk,
        SUM(r.ws_net_paid) AS total_sales,
        COALESCE(rt.total_returned, 0) AS total_returns,
        CASE
            WHEN SUM(r.ws_net_paid) > 1000 THEN 'High Value' 
            ELSE 'Standard Value'
        END AS value_category
    FROM
        web_sales r
    LEFT JOIN
        ReturnedItems rt ON r.ws_item_sk = rt.wr_item_sk
    GROUP BY
        r.ws_item_sk
)
SELECT
    ws.ws_item_sk,
    ws.ws_order_number,
    COALESCE(ws.ws_net_paid, 0) AS net_paid,
    hvr.total_sales,
    hvr.total_returns,
    hvr.value_category,
    (hvr.total_sales - hvr.total_returns) AS net_value,
    CASE
        WHEN hvr.total_sales IS NULL THEN 'No Sales'
        WHEN hvr.total_sales = 0 THEN 'Zero Sales'
        ELSE 'Sold'
    END AS sales_status
FROM
    RankedSales ws
JOIN
    HighValueReturns hvr ON ws.ws_item_sk = hvr.ws_item_sk
WHERE
    ws.rn = 1
    OR (hvr.total_returns > 10 AND hvr.value_category = 'High Value')
ORDER BY
    hvr.value_category, net_value DESC;
