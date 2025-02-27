
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN 100 AND 200
),
MaxReturns AS (
    SELECT
        cr.returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        COUNT(DISTINCT cr_order_number) AS return_count
    FROM
        catalog_returns cr
    GROUP BY
        cr.returning_customer_sk
    HAVING
        COUNT(DISTINCT cr_order_number) > 3
),
CustomerProfile AS (
    SELECT
        cu.c_customer_sk,
        cd.cd_gender,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential
    FROM
        customer cu
    LEFT JOIN customer_demographics cd ON cu.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cu.c_customer_sk = hd.hd_demo_sk
    WHERE
        cd.cd_marital_status IS NOT NULL
    GROUP BY
        cu.c_customer_sk, cd.cd_gender, hd.hd_buy_potential
),
SalesAndReturns AS (
    SELECT
        cp.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COALESCE(mr.total_returned_quantity, 0) AS total_returns
    FROM
        CustomerProfile cp
    LEFT JOIN web_sales ws ON cp.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN MaxReturns mr ON cp.c_customer_sk = mr.returning_customer_sk
    GROUP BY
        cp.c_customer_sk
)
SELECT
    sr.c_customer_sk,
    sr.total_sales,
    sr.total_returns,
    (sr.total_sales - sr.total_returns) AS net_sales,
    CASE
        WHEN sr.total_sales = 0 THEN NULL
        ELSE ROUND((sr.total_returns::decimal / sr.total_sales) * 100, 2)
    END AS return_percentage,
    RANK() OVER (ORDER BY net_sales DESC) AS sales_rank
FROM
    SalesAndReturns sr
WHERE
    (sr.total_returns IS NOT NULL OR sr.total_sales > 1000)
ORDER BY
    sales_rank, sr.c_customer_sk;
