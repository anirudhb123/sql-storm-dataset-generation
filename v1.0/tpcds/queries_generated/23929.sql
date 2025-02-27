
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rnk
    FROM
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL AND
        ws.ws_sold_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
),
CustomerReturns AS (
    SELECT
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returned,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count
    FROM
        store_returns sr
    WHERE
        sr.sr_returned_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year < 2023)
    GROUP BY
        sr.sr_item_sk
),
SelectedItemSales AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        COALESCE(SUM(rs.ws_sales_price * rs.ws_quantity), 0) AS total_sales,
        COALESCE(cr.total_returned, 0) AS total_returns
    FROM
        item i
    LEFT JOIN
        RankedSales rs ON i.i_item_sk = rs.ws_item_sk AND rs.rnk = 1
    LEFT JOIN
        CustomerReturns cr ON i.i_item_sk = cr.sr_item_sk
    GROUP BY
        i.i_item_sk, i.i_item_id
)
SELECT
    s.i_item_id,
    s.total_sales,
    s.total_returns,
    CASE
        WHEN s.total_sales = 0 THEN NULL
        ELSE ROUND((s.total_returns::DECIMAL / s.total_sales) * 100, 2)
    END AS return_rate_percentage
FROM
    SelectedItemSales s
WHERE
    (s.total_returns IS NOT NULL AND s.total_returns > 0) OR
    (s.total_sales IS NOT NULL AND s.total_sales > 1000)
ORDER BY
    return_rate_percentage DESC NULLS LAST;
