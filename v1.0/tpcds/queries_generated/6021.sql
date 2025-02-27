
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        ws_sold_date_sk AS sale_date,
        ws_quantity AS quantity,
        ws_net_paid AS total_sales,
        d_year AS sale_year,
        d_month_seq AS sale_month
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    WHERE 
        d_year = 2023
),
SalesByCustomer AS (
    SELECT 
        customer_id,
        SUM(quantity) AS total_quantity,
        SUM(total_sales) AS total_sales_amount,
        COUNT(DISTINCT sale_date) AS total_sale_days
    FROM 
        SalesData
    GROUP BY 
        customer_id
),
HighValueCustomers AS (
    SELECT 
        customer_id,
        total_quantity,
        total_sales_amount,
        total_sale_days,
        RANK() OVER (ORDER BY total_sales_amount DESC) AS sales_rank
    FROM 
        SalesByCustomer
    WHERE 
        total_sales_amount > 1000
),
SalesOverview AS (
    SELECT 
        d_year,
        d_month_seq,
        COUNT(DISTINCT customer_id) AS unique_customers,
        SUM(total_sales_amount) AS monthly_sales,
        AVG(total_sales_amount) AS avg_sales_per_customer
    FROM 
        SalesData
    JOIN 
        HighValueCustomers ON SalesData.customer_id = HighValueCustomers.customer_id
    GROUP BY 
        d_year, d_month_seq
)
SELECT 
    o.d_year,
    o.d_month_seq,
    o.unique_customers,
    o.monthly_sales,
    o.avg_sales_per_customer
FROM 
    SalesOverview o
JOIN 
    date_dim d ON o.d_year = d.d_year AND o.d_month_seq = d.d_month_seq
ORDER BY 
    o.d_year, o.d_month_seq;
