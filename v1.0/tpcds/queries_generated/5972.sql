
WITH RankedSales AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        RANK() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk IN (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 6
        )
    GROUP BY
        ws_bill_customer_sk
),
CustomerInfo AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        r.r_reason_desc,
        rs.total_sales,
        rs.order_count
    FROM
        RankedSales rs
    JOIN customer c ON rs.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN reason r ON r.r_reason_sk = (SELECT TOP 1 sr_reason_sk FROM store_returns sr WHERE sr.sr_customer_sk = c.c_customer_sk ORDER BY sr_return_amt DESC)
)
SELECT
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    SUM(ci.total_sales) AS total_sales_sum,
    AVG(ci.order_count) AS avg_order_count
FROM
    CustomerInfo ci
GROUP BY
    ci.c_customer_id, ci.cd_gender, ci.cd_marital_status, ci.cd_purchase_estimate
HAVING
    SUM(ci.total_sales) > 1000
ORDER BY
    total_sales_sum DESC
LIMIT 10;
