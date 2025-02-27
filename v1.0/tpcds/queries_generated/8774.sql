
WITH SalesData AS (
    SELECT 
        ws.ws_sales_price,
        ws.ws_quantity,
        c.c_gender,
        c.c_birth_year,
        d.d_year,
        w.w_warehouse_name,
        sm.sm_type
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2022
),
AggregatedSales AS (
    SELECT 
        c_gender,
        c_birth_year,
        w_warehouse_name,
        sm_type,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        COUNT(*) AS transaction_count
    FROM SalesData
    GROUP BY c_gender, c_birth_year, w_warehouse_name, sm_type
)
SELECT 
    c_gender,
    c_birth_year,
    w_warehouse_name,
    sm_type,
    total_sales,
    transaction_count,
    RANK() OVER (PARTITION BY c_gender ORDER BY total_sales DESC) AS sales_rank
FROM AggregatedSales
WHERE transaction_count > 100
ORDER BY c_gender, sales_rank;
