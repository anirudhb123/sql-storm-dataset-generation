
WITH daily_sales AS (
    SELECT
        d.d_date AS sales_date,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(CASE WHEN c.c_gender = 'F' THEN ws.ws_ext_sales_price ELSE 0 END) AS female_sales,
        SUM(CASE WHEN c.c_gender = 'M' THEN ws.ws_ext_sales_price ELSE 0 END) AS male_sales
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        d.d_date
),
avg_sales AS (
    SELECT 
        AVG(total_sales) AS average_sales
    FROM 
        daily_sales
),
sales_ranked AS (
    SELECT 
        sales_date,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank,
        DENSE_RANK() OVER (PARTITION BY EXTRACT(MONTH FROM sales_date) ORDER BY total_sales DESC) AS monthly_rank
    FROM 
        daily_sales
),
sales_analysis AS (
    SELECT 
        ds.sales_date,
        ds.total_sales,
        ds.total_orders,
        ds.female_sales,
        ds.male_sales,
        avg.average_sales,
        CASE 
            WHEN ds.total_sales > avg.average_sales THEN 'Above Average'
            WHEN ds.total_sales = avg.average_sales THEN 'Average'
            ELSE 'Below Average'
        END AS sales_performance
    FROM 
        daily_sales ds
    CROSS JOIN 
        avg_sales avg
)
SELECT 
    sa.sales_date,
    sa.total_sales,
    sa.total_orders,
    sa.female_sales,
    sa.male_sales,
    sa.sales_performance,
    sr.sales_rank,
    sr.monthly_rank,
    CASE 
        WHEN sa.total_sales IS NULL THEN 'Data Not Available'
        ELSE CAST(sa.total_sales AS varchar(20))
    END AS sales_display
FROM 
    sales_analysis sa
LEFT JOIN 
    sales_ranked sr ON sa.sales_date = sr.sales_date
WHERE 
    sa.sales_performance = 'Above Average'
ORDER BY 
    sa.total_sales DESC
LIMIT 10;
