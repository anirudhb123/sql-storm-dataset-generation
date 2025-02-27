
WITH SalesData AS (
    SELECT
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
        DATE_FORMAT(dd.d_date, '%Y-%m') AS sales_month
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE
        dd.d_year = 2023
        AND c.c_first_shipto_date_sk IS NOT NULL
    GROUP BY
        ws.web_site_id,
        sales_month
),
ReturnsData AS (
    SELECT
        wr.wr_web_page_sk,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_value,
        COUNT(DISTINCT wr.wr_order_number) AS total_return_orders,
        DATE_FORMAT(dd.d_date, '%Y-%m') AS return_month
    FROM
        web_returns wr
    JOIN
        date_dim dd ON wr.wr_returned_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
    GROUP BY
        wr.wr_web_page_sk,
        return_month
)
SELECT
    sd.web_site_id,
    sd.total_quantity,
    sd.total_sales,
    sd.total_orders,
    sd.avg_order_value,
    COALESCE(rd.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(rd.total_return_value, 0) AS total_return_value,
    COALESCE(rd.total_return_orders, 0) AS total_return_orders,
    sd.sales_month
FROM
    SalesData sd
LEFT JOIN
    ReturnsData rd ON sd.web_site_id = rd.wr_web_page_sk AND sd.sales_month = rd.return_month
ORDER BY
    sd.sales_month, sd.web_site_id;
