
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.order_number,
        ws.sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_sales_price DESC) AS sale_rank,
        DENSE_RANK() OVER (ORDER BY ws_sales_price DESC) AS dense_sale_rank
    FROM
        web_sales ws
    JOIN
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE
        c.c_birth_year IS NOT NULL
        AND (c.c_preferred_cust_flag = 'Y' OR c.c_email_address LIKE '%@example.com')
),
ReturnSummary AS (
    SELECT
        cr.returning_customer_sk,
        SUM(cr.return_amount) AS total_returned,
        COUNT(cr.return_quantity) AS total_returns,
        COUNT(DISTINCT cr.order_number) AS distinct_orders
    FROM
        catalog_returns cr
    WHERE
        cr.returning_customer_sk IS NOT NULL
        AND cr.return_quantity > 0
    GROUP BY
        cr.returning_customer_sk
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM
        customer_demographics cd
    LEFT JOIN
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
)
SELECT
    rd.web_site_sk,
    SUM(rd.sales_price) AS total_sales_value,
    COALESCE(rs.total_returned, 0) AS total_returns_value,
    COUNT(DISTINCT rd.order_number) AS order_count,
    SUM(CASE WHEN cd.income_band IS NOT NULL THEN 1 ELSE 0 END) AS customers_with_income_band,
    COUNT(c.c_customer_id) AS total_customers
FROM
    RankedSales rd
LEFT JOIN
    ReturnSummary rs ON rd.order_number = rs.returning_customer_sk
LEFT JOIN
    CustomerDemographics cd ON cd.cd_demo_sk IN (SELECT DISTINCT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_id = rd.web_site_sk)
JOIN
    warehouse w ON w.w_warehouse_sk = rd.web_site_sk
WHERE
    w.w_country IS NOT NULL
    AND w.w_warehouse_name NOT LIKE '%Test%'
GROUP BY
    rd.web_site_sk
HAVING
    SUM(rd.sales_price) > 10000
ORDER BY
    total_sales_value DESC, total_returns_value ASC
FETCH FIRST 500 ROWS ONLY;
