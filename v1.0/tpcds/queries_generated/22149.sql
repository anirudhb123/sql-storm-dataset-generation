
WITH RankedSales AS (
    SELECT
        ws.web_site_id,
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        c.c_first_shipto_date_sk IS NOT NULL
        AND (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
    GROUP BY
        ws.web_site_id, ws_sold_date_sk
),
DateFiltered AS (
    SELECT
        d.d_date_sk,
        d.d_year,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM
        date_dim d
    LEFT JOIN
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE
        d.d_year BETWEEN 2020 AND 2022
        AND (ws.ws_order_number IS NULL OR ws.ws_order_number % 2 = 0)
    GROUP BY
        d.d_date_sk, d.d_year
),
SalesSummary AS (
    SELECT
        r.web_site_id,
        d.d_year,
        COALESCE(SUM(r.total_sales), 0) AS total_sales,
        COALESCE(SUM(CASE WHEN r.sales_rank = 1 THEN r.total_sales ELSE 0 END), 0) AS highest_sales
    FROM
        RankedSales r
    FULL OUTER JOIN
        DateFiltered d ON r.ws_sold_date_sk = d.d_date_sk
    GROUP BY
        r.web_site_id, d.d_year
)
SELECT
    s.web_site_id,
    s.d_year,
    s.total_sales,
    s.highest_sales,
    CASE 
        WHEN s.total_sales > 10000 THEN 'High Sales'
        WHEN s.total_sales IS NULL THEN 'No Sales'
        ELSE 'Moderate Sales'
    END AS sales_category
FROM
    SalesSummary s
WHERE
    (s.total_sales < 30000 OR s.highest_sales IS NULL)
ORDER BY
    s.d_year DESC, s.web_site_id;
