
WITH SalesData AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_sold_date_sk,
        ws.ws_ship_mode_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS SalesRank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND ws.ws_sold_date_sk <= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
),
AggregateSales AS (
    SELECT
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS TotalQuantity,
        SUM(sd.ws_net_paid) AS TotalNetPaid
    FROM
        SalesData sd
    WHERE
        sd.SalesRank <= 10
    GROUP BY
        sd.ws_item_sk
),
ItemDetails AS (
    SELECT
        i.i_item_id,
        i.i_current_price,
        i.i_item_desc,
        COALESCE(ib.ib_lower_bound, 0) AS IncomeLower,
        COALESCE(ib.ib_upper_bound, 999999) AS IncomeUpper
    FROM
        item i
    LEFT JOIN
        income_band ib ON i.i_item_sk = ib.ib_income_band_sk
),
RankedSales AS (
    SELECT
        a.ws_item_sk,
        a.TotalQuantity,
        a.TotalNetPaid,
        d.i_item_desc,
        d.i_current_price,
        CASE
            WHEN a.TotalNetPaid > d.i_current_price * a.TotalQuantity THEN 'OVERPAID'
            WHEN a.TotalNetPaid < d.i_current_price * a.TotalQuantity THEN 'UNDERPAID'
            ELSE 'EXACT'
        END AS PaymentStatus
    FROM
        AggregateSales a
    JOIN
        ItemDetails d ON a.ws_item_sk = d.i_item_id
)
SELECT
    r.ws_item_sk,
    r.i_item_desc,
    r.TotalQuantity,
    r.TotalNetPaid,
    r.i_current_price,
    r.PaymentStatus
FROM
    RankedSales r
WHERE
    r.TotalNetPaid IS NOT NULL
    AND r.TotalQuantity > 0
ORDER BY
    CASE
        WHEN r.PaymentStatus = 'OVERPAID' THEN 1
        WHEN r.PaymentStatus = 'UNDERPAID' THEN 2
        ELSE 3
    END,
    r.TotalNetPaid DESC,
    r.TotalQuantity ASC
LIMIT 100
OFFSET (SELECT COUNT(*) FROM RankedSales) - 100;
