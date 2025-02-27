
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        dd.d_year = 2023
        AND cd.cd_gender = 'F'
    GROUP BY
        ws.web_site_sk,
        ws.ws_order_number
),
TopWebSites AS (
    SELECT
        r.web_site_sk,
        r.total_quantity,
        r.total_sales,
        r.total_discount
    FROM
        RankedSales r
    WHERE
        r.sales_rank <= 5
)
SELECT
    w.w_warehouse_name,
    SUM(t.total_sales) AS warehouse_sales,
    SUM(t.total_discount) AS warehouse_discounts,
    COUNT(t.total_quantity) AS total_orders
FROM
    TopWebSites t
JOIN
    warehouse w ON t.web_site_sk = w.w_warehouse_sk
GROUP BY
    w.w_warehouse_name
ORDER BY
    warehouse_sales DESC;
