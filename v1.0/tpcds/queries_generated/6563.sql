
WITH SalesStats AS (
    SELECT 
        c.ca_state,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_sales_price) AS total_sales,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers
    FROM 
        store_sales ss 
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk 
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.ca_state
),
Ranking AS (
    SELECT 
        ca_state,
        total_quantity,
        total_sales,
        avg_sales_price,
        unique_customers,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesStats
)
SELECT 
    r.ca_state,
    r.total_quantity,
    r.total_sales,
    r.avg_sales_price,
    r.unique_customers,
    r.sales_rank
FROM 
    Ranking r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.total_sales DESC;
