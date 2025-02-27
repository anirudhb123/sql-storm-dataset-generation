
WITH sales_data AS (
    SELECT
        ws.web_site_id,
        c.c_gender,
        d.d_year,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year BETWEEN 2020 AND 2023
    GROUP BY ws.web_site_id, c.c_gender, d.d_year
),
ranked_sales AS (
    SELECT
        web_site_id,
        c_gender,
        d_year,
        total_sales,
        total_orders,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM sales_data
)
SELECT
    web_site_id,
    c_gender,
    d_year,
    total_sales,
    total_orders,
    sales_rank
FROM ranked_sales
WHERE sales_rank <= 10
ORDER BY d_year, sales_rank;
