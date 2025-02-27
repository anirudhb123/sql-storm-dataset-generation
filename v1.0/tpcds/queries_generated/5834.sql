
WITH RankedSales AS (
    SELECT
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank_sales
    FROM
        web_sales ws
    JOIN
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 2400 AND 2450
    GROUP BY
        ws.web_site_id
),
TopWebSites AS (
    SELECT
        r.web_site_id,
        r.total_sales,
        r.order_count
    FROM
        RankedSales r
    WHERE
        r.rank_sales <= 10
),
CustomerDemographics AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN
        TopWebSites tw ON ws.ws_web_site_sk = tw.web_site_sk
    GROUP BY
        cd.cd_gender,
        cd.cd_marital_status
)
SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count,
    cd.total_sales,
    ROUND(cd.total_sales / NULLIF(cd.customer_count, 0), 2) AS avg_sales_per_customer
FROM
    CustomerDemographics cd
ORDER BY
    cd.total_sales DESC;
