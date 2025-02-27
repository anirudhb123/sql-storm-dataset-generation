
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
SalesData AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales_amt,
        COUNT(DISTINCT ws_order_number) AS sales_count
    FROM
        web_sales
    WHERE
        ws_sold_date_sk IN (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_year = 2023
        )
    GROUP BY
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        h.hd_income_band_sk,
        s.s_store_sk,
        s.s_store_name
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
    LEFT JOIN store s ON c.c_current_addr_sk = s.s_store_sk
),
ReturnSalesComparison AS (
    SELECT
        cd.c_customer_sk,
        cd.cd_gender,
        cd.hd_income_band_sk,
        COALESCE(cr.total_return_amt, 0) AS total_return,
        COALESCE(sd.total_sales_amt, 0) AS total_sales,
        COUNT(DISTINCT s.s_store_sk) AS store_count,
        AVG(COALESCE(cr.total_return_amt, 0) - COALESCE(sd.total_sales_amt, 0)) AS avg_difference
    FROM
        CustomerDemographics cd
    LEFT JOIN CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
    LEFT JOIN store s ON cd.s_store_sk = s.s_store_sk
    GROUP BY
        cd.c_customer_sk,
        cd.cd_gender,
        cd.hd_income_band_sk
)
SELECT
    rsc.cd_gender,
    rsc.hd_income_band_sk,
    COUNT(rsc.c_customer_sk) AS customer_count,
    SUM(rsc.total_return) AS total_return,
    SUM(rsc.total_sales) AS total_sales,
    AVG(rsc.avg_difference) AS avg_return_sales_difference
FROM
    ReturnSalesComparison rsc
WHERE
    rsc.total_sales > 0
GROUP BY
    rsc.cd_gender,
    rsc.hd_income_band_sk
ORDER BY
    rsc.cd_gender,
    rsc.hd_income_band_sk;
