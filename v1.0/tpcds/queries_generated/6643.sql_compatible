
WITH SalesAggregates AS (
    SELECT 
        d.d_year,
        c.c_gender,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        AVG(ws.ws_list_price) AS average_list_price,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2018 AND 2022
    GROUP BY 
        d.d_year, c.c_gender
),
SalesComparison AS (
    SELECT
        sa.d_year,
        sa.c_gender,
        sa.total_sales,
        sa.average_list_price,
        sa.total_orders,
        LAG(sa.total_sales) OVER (PARTITION BY sa.c_gender ORDER BY sa.d_year) AS prev_year_sales
    FROM 
        SalesAggregates sa
)
SELECT 
    sc.d_year,
    sc.c_gender,
    sc.total_sales,
    sc.average_list_price,
    sc.total_orders,
    (sc.total_sales - COALESCE(sc.prev_year_sales, 0)) AS sales_growth,
    CASE 
        WHEN sc.total_sales > COALESCE(sc.prev_year_sales, 0) THEN 'Increase'
        WHEN sc.total_sales < COALESCE(sc.prev_year_sales, 0) THEN 'Decrease'
        ELSE 'No Change'
    END AS growth_trend
FROM 
    SalesComparison sc
ORDER BY 
    sc.c_gender, sc.d_year;
