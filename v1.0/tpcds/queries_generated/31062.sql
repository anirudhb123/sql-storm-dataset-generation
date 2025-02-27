
WITH RECURSIVE SalesCTE AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rn
    FROM
        web_sales
    WHERE
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerReturns AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt_inc_tax) AS total_invoice
    FROM
        web_returns
    GROUP BY
        wr_item_sk
),
SalesSummary AS (
    SELECT
        s.ws_item_sk,
        SUM(s.ws_quantity) AS total_sales,
        SUM(s.ws_sales_price) AS total_revenue,
        COALESCE(r.total_returned, 0) AS total_returns,
        COALESCE(r.total_invoice, 0) AS total_invoice
    FROM
        SalesCTE s
    LEFT JOIN
        CustomerReturns r ON s.ws_item_sk = r.wr_item_sk
    GROUP BY
        s.ws_item_sk
),
IncomeRanges AS (
    SELECT
        ib_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM
        customer c
    JOIN
        household_demographics h ON c.c_current_cdemo_sk = h.hd_demo_sk
    JOIN
        income_band i ON h.hd_income_band_sk = i.ib_income_band_sk
    GROUP BY
        ib_income_band_sk
)
SELECT
    ss.ws_item_sk,
    ss.total_sales,
    ss.total_revenue,
    ss.total_returns,
    ss.total_invoice,
    ir.ib_income_band_sk,
    ir.customer_count,
    (ss.total_revenue - ss.total_invoice) AS net_profit
FROM
    SalesSummary ss
LEFT JOIN
    IncomeRanges ir ON ss.ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_item_sk = ss.ws_item_sk)
WHERE
    ss.total_sales > 0
ORDER BY
    net_profit DESC
LIMIT 10;
