
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        RANK() OVER (PARTITION BY d.d_year, d.d_month_seq ORDER BY ws.ws_sales_price DESC) AS rank_price
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023 AND
        cd.cd_marital_status = 'M'
)
SELECT
    rs.web_site_sk,
    SUM(rs.ws_sales_price * rs.ws_quantity) AS total_revenue,
    COUNT(*) AS total_sales,
    AVG(rs.ws_sales_price) AS average_price,
    COUNT(DISTINCT rs.cd_gender) AS unique_genders
FROM
    RankedSales rs
WHERE
    rs.rank_price <= 10
GROUP BY
    rs.web_site_sk
ORDER BY
    total_revenue DESC;
