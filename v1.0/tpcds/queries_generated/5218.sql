
WITH SalesData AS (
    SELECT 
        d.d_year,
        c.c_gender,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2023
    GROUP BY 
        d.d_year, c.c_gender
),
RankedSales AS (
    SELECT 
        d_year,
        c_gender,
        total_quantity,
        total_sales,
        avg_sales_price,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    d_year,
    c_gender,
    total_quantity,
    total_sales,
    avg_sales_price
FROM 
    RankedSales
WHERE 
    sales_rank <= 5
ORDER BY 
    d_year, sales_rank;
