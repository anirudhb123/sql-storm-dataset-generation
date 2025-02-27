
WITH ranked_sales AS (
    SELECT
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
        AND cd.cd_gender = 'F'
    GROUP BY
        ws.web_site_id
),
top_web_sites AS (
    SELECT
        web_site_id,
        total_sales,
        total_orders
    FROM
        ranked_sales
    WHERE
        sales_rank <= 10
)
SELECT
    w.web_name,
    tws.total_sales,
    tws.total_orders,
    ROUND((tws.total_sales / NULLIF(tws.total_orders, 0)), 2) AS avg_order_value
FROM
    top_web_sites tws
JOIN
    web_site w ON tws.web_site_id = w.web_site_id
ORDER BY
    tws.total_sales DESC;
