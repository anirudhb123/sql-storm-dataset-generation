
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.net_paid) AS total_sales,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.net_paid) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023 AND
        cd.cd_marital_status = 'M' AND 
        cd.cd_gender = 'F'
    GROUP BY
        ws.web_site_sk, ws.web_site_id
),
TopWebsites AS (
    SELECT
        web_site_sk,
        web_site_id,
        total_sales,
        total_orders
    FROM
        RankedSales
    WHERE
        sales_rank <= 5
)
SELECT
    tw.web_site_id,
    tw.total_sales,
    tw.total_orders,
    SUM(ca.ca_gmt_offset) AS total_gmt_offset
FROM
    TopWebsites tw
JOIN
    web_site ws ON tw.web_site_sk = ws.web_site_sk
JOIN
    customer_address ca ON ws.web_site_id = ca.ca_address_id
GROUP BY
    tw.web_site_id, tw.total_sales, tw.total_orders
ORDER BY
    tw.total_sales DESC;
