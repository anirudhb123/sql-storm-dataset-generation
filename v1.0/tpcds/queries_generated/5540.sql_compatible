
WITH SalesData AS (
    SELECT 
        d.d_year,
        c.c_gender,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS number_of_sales,
        AVG(ss.ss_quantity) AS avg_quantity,
        SUM(ss.ss_ext_discount_amt) AS total_discount
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2021
    GROUP BY 
        d.d_year, c.c_gender
),
RankedSales AS (
    SELECT 
        d_year,
        c_gender,
        total_sales,
        number_of_sales,
        avg_quantity,
        total_discount,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    d_year,
    c_gender,
    total_sales,
    number_of_sales,
    avg_quantity,
    total_discount,
    sales_rank
FROM 
    RankedSales
WHERE 
    sales_rank <= 10
ORDER BY 
    d_year, sales_rank;
