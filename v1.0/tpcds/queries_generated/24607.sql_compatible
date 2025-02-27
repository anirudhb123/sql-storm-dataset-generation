
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS rank_paid,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS rank_price
    FROM
        web_sales ws
    WHERE
        ws.ws_net_paid IS NOT NULL
        AND ws.ws_net_paid > 0
),
CustomerReturns AS (
    SELECT
        wr.wr_item_sk,
        COUNT(wr.wr_return_quantity) AS return_count,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM
        web_returns wr
    WHERE
        wr.wr_return_amt IS NOT NULL
        AND wr.wr_return_quantity > 0
    GROUP BY
        wr.wr_item_sk
),
AggregatedData AS (
    SELECT
        ws.ws_item_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        COALESCE(cr.return_count, 0) AS total_returns,
        COALESCE(cr.total_return_amt, 0) AS total_return_amount,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_ext_sales_price) AS total_ext_sales
    FROM
        web_sales ws
    LEFT JOIN
        CustomerReturns cr ON ws.ws_item_sk = cr.wr_item_sk
    GROUP BY
        ws.ws_item_sk
)
SELECT
    ad.ws_item_sk,
    ad.total_orders,
    ad.total_quantity,
    ad.total_returns,
    ad.total_return_amount,
    ROUND(ad.total_net_paid, 2) AS net_revenue,
    ROUND(ad.total_ext_sales, 2) AS gross_revenue,
    CASE 
        WHEN ad.total_returns > 0 THEN ROUND((ad.total_return_amount / NULLIF(ad.total_net_paid, 0)) * 100, 2)
        ELSE 0
    END AS return_percentage,
    CASE 
        WHEN MAX(rs.rank_paid) = 1 AND MAX(rs.rank_price) = 1 THEN 'Top Performer'
        WHEN MAX(rs.rank_paid) < 4 THEN 'Promising'
        ELSE 'Needs Improvement'
    END AS performance_category
FROM
    AggregatedData ad
LEFT JOIN
    RankedSales rs ON ad.ws_item_sk = rs.ws_item_sk
GROUP BY
    ad.ws_item_sk, ad.total_orders, ad.total_quantity, ad.total_returns, ad.total_return_amount
ORDER BY
    net_revenue DESC
LIMIT 100;
