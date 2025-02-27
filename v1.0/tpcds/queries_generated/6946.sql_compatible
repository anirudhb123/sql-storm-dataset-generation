
WITH sales_summary AS (
    SELECT
        d.d_year,
        s.s_store_name,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM
        web_sales AS ws
    JOIN
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN
        store AS s ON ws.ws_ship_addr_sk = s.s_address_sk
    WHERE
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY
        d.d_year,
        s.s_store_name
),
top_sales AS (
    SELECT
        d_year,
        s_store_name,
        total_sales,
        total_orders,
        avg_sales_price,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM
        sales_summary
)
SELECT
    d_year,
    s_store_name,
    total_sales,
    total_orders,
    avg_sales_price
FROM
    top_sales
WHERE
    sales_rank <= 5
ORDER BY
    d_year ASC,
    total_sales DESC;
