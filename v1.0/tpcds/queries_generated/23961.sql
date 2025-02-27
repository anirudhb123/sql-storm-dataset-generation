
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
CustomerReturns AS (
    SELECT
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returned
    FROM
        catalog_returns
    WHERE
        cr_return_quantity IS NOT NULL
    GROUP BY
        cr_item_sk
),
SalesAndReturns AS (
    SELECT
        r.ws_item_sk,
        r.total_sold,
        COALESCE(c.total_returned, 0) AS total_returned,
        CASE 
            WHEN r.total_sold IS NOT NULL AND COALESCE(c.total_returned, 0) > r.total_sold THEN 'Over Returned'
            ELSE 'Normal'
        END AS return_status
    FROM
        RankedSales r
    LEFT JOIN CustomerReturns c ON r.ws_item_sk = c.cr_item_sk
),
SalesSummary AS (
    SELECT
        ss.sold_date_sk,
        s.store_sk,
        SUM(ss.net_profit) AS total_net_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT s.s_store_id) AS unique_stores
    FROM
        store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE
        ss.sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ss.sold_date_sk, s.store_sk
),
FinalReport AS (
    SELECT
        sar.ws_item_sk,
        sar.total_sold,
        sar.total_returned,
        sar.return_status,
        ss.total_net_profit,
        ss.total_quantity,
        ss.unique_stores,
        CASE
            WHEN sar.total_sold > 100 THEN 'High Seller'
            ELSE 'Low Seller'
        END AS seller_category
    FROM
        SalesAndReturns sar
    JOIN SalesSummary ss ON sar.ws_item_sk = ss.sold_date_sk
)
SELECT
    *,
    CONCAT(seller_category, ' - ', return_status) AS final_status
FROM
    FinalReport
WHERE
    total_returned > 0 OR seller_category = 'High Seller'
ORDER BY
    total_net_profit DESC NULLS LAST
LIMIT 50;
