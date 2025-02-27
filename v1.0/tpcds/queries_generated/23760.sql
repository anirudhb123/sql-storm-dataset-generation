
WITH RankedReturns AS (
    SELECT
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM
        store_returns
    WHERE
        sr_return_quantity > 0
),
ItemSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_net_paid) AS total_net_paid
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
CombinedStats AS (
    SELECT
        irsr.sr_item_sk,
        irsr.sr_return_quantity,
        irsr.sr_return_amt,
        isales.total_sales,
        isales.total_net_paid,
        CASE
            WHEN isales.total_sales IS NULL OR isales.total_sales = 0 THEN NULL
            ELSE irsr.sr_return_amt / isales.total_sales
        END AS return_rate
    FROM
        RankedReturns irsr
    LEFT JOIN
        ItemSales isales ON irsr.sr_item_sk = isales.ws_item_sk
    WHERE
        irsr.rn = 1
)
SELECT
    COUNT(*) AS total_items,
    AVG(total_sales) AS avg_sales,
    SUM(CASE WHEN return_rate IS NOT NULL THEN return_rate ELSE 0 END) AS total_return_rate,
    MAX(total_net_paid) AS max_net_paid,
    STRING_AGG(DISTINCT CAST(sr_item_sk AS VARCHAR), ', ') AS returned_items
FROM
    CombinedStats
WHERE
    total_sales > 100
    AND return_rate IS NOT NULL
GROUP BY
    CASE WHEN MAX(return_rate) < 0.1 THEN 'Low Return Rate' ELSE 'High Return Rate' END
HAVING
    SUM(total_net_paid) > 1000
    AND COUNT(DISTINCT sr_item_sk) > 5;
