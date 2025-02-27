
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        c.c_customer_sk,
        c.c_gender,
        c.c_birth_year,
        d.d_year,
        sm.sm_type
    FROM web_sales AS ws
    JOIN customer AS c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN date_dim AS d ON ws.ws_ship_date_sk = d.d_date_sk
    JOIN ship_mode AS sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year BETWEEN 2021 AND 2023 AND sm.sm_type IN ('Standard Class', 'Second Day Air')
),
SalesSummary AS (
    SELECT 
        d_year,
        c_gender,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_ext_sales_price) AS avg_sales_price
    FROM SalesData
    GROUP BY d_year, c_gender
)
SELECT 
    d_year,
    c_gender,
    total_orders,
    total_quantity,
    total_sales,
    avg_sales_price,
    RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM SalesSummary
ORDER BY d_year, sales_rank;
