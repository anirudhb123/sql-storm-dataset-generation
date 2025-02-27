
WITH RankedSales AS (
    SELECT
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE
        d.d_year = 2023
        AND cd.cd_marital_status = 'M'
    GROUP BY
        ws.web_site_id
), TopSales AS (
    SELECT
        web_site_id,
        total_sales,
        total_orders
    FROM
        RankedSales
    WHERE
        sales_rank <= 5
)
SELECT
    t.web_site_id,
    t.total_sales,
    t.total_orders,
    w.w_country,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers
FROM
    TopSales t
JOIN
    web_site w ON t.web_site_id = w.web_site_id
JOIN
    web_sales ws ON t.web_site_id = ws.ws_web_site_sk
JOIN
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
GROUP BY
    t.web_site_id, t.total_sales, t.total_orders, w.w_country
ORDER BY
    t.total_sales DESC;
