
WITH RankedReturns AS (
    SELECT
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rnk
    FROM store_returns
    WHERE sr_return_quantity > 1
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_credit_rating,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        coalesce(hd.hd_buy_potential, 'UNKNOWN') AS buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cd.cd_gender = 'F' AND cd.cd_purchase_estimate > 1000
),
SalesData AS (
    SELECT
        s.ss_item_sk,
        SUM(s.ss_sales_price) AS total_sales,
        SUM(s.ss_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT s.ss_ticket_number) AS sales_count
    FROM store_sales s
    WHERE s.ss_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d WHERE d.d_year = 2023)
                                AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY s.ss_item_sk
),
ReturnSummary AS (
    SELECT
        r.sr_item_sk,
        COUNT(*) AS return_count,
        SUM(r.sr_return_amt) AS total_return_amount,
        AVG(r.sr_return_quantity) AS avg_return_quantity
    FROM RankedReturns r
    WHERE r.rnk <= 5
    GROUP BY r.sr_item_sk
)
SELECT
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_credit_rating,
    ci.buy_potential,
    CASE
        WHEN rs.total_sales IS NULL THEN 'No Sales'
        ELSE 'Has Sales'
    END AS sales_status,
    COALESCE(rs.total_sales, 0) AS total_sales,
    COALESCE(rs.total_discount, 0) AS total_discount,
    COALESCE(rs.sales_count, 0) AS sales_count,
    COALESCE(rs2.return_count, 0) AS return_count,
    COALESCE(rs2.total_return_amount, 0) AS total_return_amount,
    COALESCE(rs2.avg_return_quantity, 0) AS avg_return_quantity
FROM CustomerInfo ci
LEFT JOIN SalesData rs ON ci.c_customer_sk = rs.ss_item_sk
LEFT JOIN ReturnSummary rs2 ON rs2.sr_item_sk = rs.ss_item_sk
WHERE (rs.total_sales > 100 OR rs.total_discount > 100) OR (rs2.return_count > 0)
ORDER BY ci.c_last_name, ci.c_first_name;
