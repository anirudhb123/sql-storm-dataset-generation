
WITH MonthlySales AS (
    SELECT
        d.d_year AS sales_year,
        d.d_month_seq AS sales_month,
        COALESCE(SUM(ws.ws_sales_price * ws.ws_quantity), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_sales_price * cs.cs_quantity), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_sales_price * ss.ss_quantity), 0) AS total_store_sales
    FROM
        date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY
        d.d_year, d.d_month_seq
),
RankedSales AS (
    SELECT
        sales_year,
        sales_month,
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        RANK() OVER (PARTITION BY sales_year ORDER BY total_web_sales DESC) AS web_sales_rank,
        RANK() OVER (PARTITION BY sales_year ORDER BY total_catalog_sales DESC) AS catalog_sales_rank,
        RANK() OVER (PARTITION BY sales_year ORDER BY total_store_sales DESC) AS store_sales_rank
    FROM
        MonthlySales
),
CustomerDemographics AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY
        cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
)
SELECT
    rs.sales_year,
    rs.sales_month,
    rs.total_web_sales,
    rs.total_catalog_sales,
    rs.total_store_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.hd_income_band_sk,
    cd.customer_count,
    CASE
        WHEN rs.total_web_sales > rs.total_catalog_sales AND rs.total_web_sales > rs.total_store_sales THEN 'Web Dominant'
        WHEN rs.total_catalog_sales > rs.total_web_sales AND rs.total_catalog_sales > rs.total_store_sales THEN 'Catalog Dominant'
        WHEN rs.total_store_sales > rs.total_web_sales AND rs.total_store_sales > rs.total_catalog_sales THEN 'Store Dominant'
        ELSE 'Balanced'
    END AS sales_dominance
FROM
    RankedSales rs
JOIN CustomerDemographics cd ON (cd.customer_count > 0 AND cd.hd_income_band_sk IS NOT NULL)
WHERE
    rs.sales_year = (SELECT MAX(sales_year) FROM RankedSales) 
ORDER BY 
    rs.sales_month, 
    cd.cd_gender, 
    cd.hd_income_band_sk;
