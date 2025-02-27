
WITH RankedSales AS (
    SELECT
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
    GROUP BY
        ws.web_site_id, ws.web_site_sk
)
SELECT
    r.web_site_id,
    r.total_sales,
    r.sales_rank,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status
FROM
    RankedSales r
JOIN
    web_site w ON r.web_site_id = w.web_site_id
JOIN
    customer c ON c.c_current_cdemo_sk = w.web_site_sk
JOIN
    customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
WHERE
    r.sales_rank <= 5
ORDER BY
    r.total_sales DESC;
