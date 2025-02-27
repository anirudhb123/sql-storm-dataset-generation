
WITH RankedReturns AS (
    SELECT
        sr.returned_date_sk,
        sr.reason_sk,
        COUNT(*) AS total_returns,
        SUM(sr.return_amt) AS total_return_amt,
        SUM(CASE 
                WHEN sr.return_quantity IS NULL THEN 0 
                ELSE sr.return_quantity 
            END) AS total_return_quantity,
        DENSE_RANK() OVER (PARTITION BY sr.reason_sk ORDER BY SUM(sr.return_amt) DESC) AS rank_by_reason
    FROM
        store_returns sr
    GROUP BY
        sr.returned_date_sk,
        sr.reason_sk
),
RecentWebSales AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS unique_orders,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY
        ws.ws_sold_date_sk,
        ws.ws_item_sk
)
SELECT
    rwa.returned_date_sk,
    rwa.reason_sk,
    rwa.total_returns,
    rwa.total_return_amt,
    rw.total_web_sales,
    rw.unique_orders,
    rw.total_net_profit,
    CASE 
        WHEN rw.total_web_sales IS NULL OR rw.total_web_sales < 1000 
        THEN 'Low'
        WHEN rw.total_web_sales >= 10000 
        THEN 'High'
        ELSE 'Medium'
    END AS sales_category
FROM
    RankedReturns rwa
LEFT JOIN
    RecentWebSales rw ON rwa.returned_date_sk = rw.ws_sold_date_sk
WHERE
    rwa.rank_by_reason <= 3
    AND (rwa.total_return_amt IS NOT NULL OR rw.total_web_sales IS NULL)
UNION ALL
SELECT 
    d.d_date_sk AS returned_date_sk,
    NULL AS reason_sk,
    0 AS total_returns,
    0 AS total_return_amt,
    0 AS total_web_sales,
    0 AS unique_orders,
    0 AS total_net_profit,
    'None' AS sales_category
FROM 
    date_dim d
WHERE 
    d.d_year = 2023
    AND NOT EXISTS (
        SELECT 1 
        FROM store_returns sr 
        WHERE sr.returned_date_sk = d.d_date_sk
    )
ORDER BY 
    returned_date_sk DESC, reason_sk;
