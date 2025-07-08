
WITH RecursiveSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING SUM(COALESCE(ws.ws_ext_sales_price, 0)) > 10000
),
MonthlySales AS (
    SELECT 
        EXTRACT(YEAR FROM dd.d_date) AS sales_year,
        EXTRACT(MONTH FROM dd.d_date) AS sales_month,
        SUM(rs.total_sales) AS monthly_total_sales
    FROM date_dim dd
    JOIN RecursiveSales rs ON dd.d_date_sk IN (
        SELECT ws.ws_sold_date_sk 
        FROM web_sales ws 
        WHERE ws.ws_bill_customer_sk = rs.c_customer_sk
    ) 
    GROUP BY EXTRACT(YEAR FROM dd.d_date), EXTRACT(MONTH FROM dd.d_date)
    ORDER BY sales_year, sales_month
),
RankedSales AS (
    SELECT 
        ms.sales_year,
        ms.sales_month,
        ms.monthly_total_sales,
        RANK() OVER (PARTITION BY ms.sales_year ORDER BY ms.monthly_total_sales DESC) AS sales_rank
    FROM MonthlySales ms
)
SELECT 
    CONCAT('Year: ', rs.sales_year, ', Month: ', rs.sales_month) AS sales_period,
    rs.monthly_total_sales,
    rs.sales_rank
FROM RankedSales rs
WHERE rs.sales_rank <= 5
ORDER BY rs.sales_year, rs.sales_month;
