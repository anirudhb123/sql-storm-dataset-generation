
WITH SalesAggregates AS (
    SELECT
        ws_item_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) as rn
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
TopSoldItems AS (
    SELECT
        sa.ws_item_sk,
        i.i_item_desc,
        i.i_brand,
        i.i_category,
        sa.total_orders,
        sa.total_quantity,
        sa.total_revenue
    FROM
        SalesAggregates sa
    JOIN
        item i ON sa.ws_item_sk = i.i_item_sk
    WHERE
        sa.rn <= 10
),
CustomerReturns AS (
    SELECT
        sr.store_sk,
        sr.returned_date_sk,
        sr.return_quantity,
        COUNT(DISTINCT sr_ticket_number) AS distinct_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr_return_tax) AS total_return_tax
    FROM
        store_returns sr
    GROUP BY
        sr.store_sk, sr.returned_date_sk
),
ReturnToSales AS (
    SELECT
        sr.store_sk,
        COUNT(DISTINCT sr.returned_date_sk) AS return_days,
        SUM(sr.return_quantity) AS total_return_items
    FROM
        CustomerReturns sr
    JOIN
        store s ON sr.store_sk = s.s_store_sk
    WHERE
        s.s_state = 'CA'
    GROUP BY
        sr.store_sk
)
SELECT
    tsi.i_item_desc,
    tsi.i_brand,
    tsi.i_category,
    tsi.total_orders,
    tsi.total_quantity,
    tsi.total_revenue,
    COALESCE(rts.return_days, 0) AS return_days,
    COALESCE(rts.total_return_items, 0) AS total_return_items,
    CASE 
        WHEN tsi.total_revenue > 10000 THEN 'High Revenue'
        WHEN tsi.total_revenue BETWEEN 5000 AND 10000 THEN 'Medium Revenue'
        ELSE 'Low Revenue' 
    END AS revenue_category
FROM
    TopSoldItems tsi
LEFT JOIN
    ReturnToSales rts ON tsi.ws_item_sk = rts.store_sk
WHERE
    tsi.total_orders > 5 OR rts.return_days IS NOT NULL
ORDER BY
    tsi.total_revenue DESC, tsi.i_item_desc ASC;
