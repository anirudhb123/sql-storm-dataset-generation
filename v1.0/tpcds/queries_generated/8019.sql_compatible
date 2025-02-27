
WITH RankedSales AS (
    SELECT
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
    GROUP BY
        ws.web_site_id
),
TopSales AS (
    SELECT
        r.web_site_id,
        r.total_sales,
        r.order_count
    FROM
        RankedSales r
    WHERE
        r.sales_rank <= 5
),
CustomerDetails AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
)
SELECT
    t.web_site_id,
    t.total_sales,
    t.order_count,
    COUNT(DISTINCT cd.c_customer_id) AS unique_customers,
    SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
    COUNT(DISTINCT hd.hd_income_band_sk) AS unique_income_bands
FROM
    TopSales t
LEFT JOIN
    CustomerDetails cd ON t.web_site_id = cd.c_customer_id
LEFT JOIN
    household_demographics hd ON cd.hd_income_band_sk = hd.hd_income_band_sk
GROUP BY
    t.web_site_id, t.total_sales, t.order_count
ORDER BY
    t.total_sales DESC;
