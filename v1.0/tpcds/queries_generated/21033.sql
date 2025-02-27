
WITH RankedReturns AS (
    SELECT
        wr_returning_customer_sk,
        SUM(wr_return_qty) AS total_returned_qty,
        RANK() OVER (PARTITION BY wr_returning_customer_sk ORDER BY SUM(wr_return_amt_inc_tax) DESC) AS rank_return
    FROM
        web_returns
    GROUP BY
        wr_returning_customer_sk
),
CustomerPurchase AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopReturners AS (
    SELECT
        rr.wr_returning_customer_sk,
        rr.total_returned_qty,
        cp.total_sales,
        cp.order_count
    FROM
        RankedReturns rr
    JOIN CustomerPurchase cp ON rr.wr_returning_customer_sk = cp.c_customer_sk
    WHERE
        rr.rank_return <= 5
        AND cp.order_count > 0
),
IncomeRanges AS (
    SELECT
        CASE 
            WHEN hd.hd_income_band_sk IS NULL THEN 'Unknown'
            WHEN hd.hd_income_band_sk = 1 THEN 'Low'
            WHEN hd.hd_income_band_sk = 2 THEN 'Medium'
            WHEN hd.hd_income_band_sk = 3 THEN 'High'
            ELSE 'Other'
        END AS income_band,
        COUNT(*) AS customer_count,
        AVG(total_sales) AS avg_sales
    FROM
        TopReturners tr
    LEFT JOIN household_demographics hd ON tr.wr_returning_customer_sk = hd.hd_demo_sk
    GROUP BY
        hd.hd_income_band_sk
)
SELECT
    ir.income_band,
    ir.customer_count,
    ir.avg_sales,
    CASE
        WHEN ir.customer_count = 0 THEN 'No Sales'
        WHEN ir.avg_sales IS NULL THEN 'Insufficient Data'
        ELSE 'Valid Data'
    END AS sales_status
FROM
    IncomeRanges ir
ORDER BY
    ir.customer_count DESC, ir.avg_sales DESC
LIMIT 10;
