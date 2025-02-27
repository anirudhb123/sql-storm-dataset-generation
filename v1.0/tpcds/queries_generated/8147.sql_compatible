
WITH RankedSales AS (
    SELECT
        ws.web_site_id,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS rank
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        ws.web_site_id
),
SalesWithDemographics AS (
    SELECT
        r.web_site_id,
        r.total_sales,
        r.order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating
    FROM
        RankedSales r
    JOIN
        customer c ON r.web_site_id = c.c_current_addr_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        r.rank <= 10
)
SELECT
    swd.web_site_id,
    swd.total_sales,
    swd.order_count,
    swd.cd_gender,
    swd.cd_marital_status,
    swd.cd_education_status,
    swd.cd_credit_rating
FROM
    SalesWithDemographics swd
JOIN
    warehouse w ON swd.web_site_id = w.w_warehouse_id
WHERE
    w.w_state IN ('CA', 'NY', 'TX')
ORDER BY
    swd.total_sales DESC;
