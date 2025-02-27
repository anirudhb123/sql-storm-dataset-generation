
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        s.s_store_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ss.ss_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d) AND (SELECT MAX(d.d_date_sk) FROM date_dim d)
    GROUP BY 
        c.c_customer_id, s.s_store_name
),
AggregateSales AS (
    SELECT 
        store_name,
        COUNT(DISTINCT customer_id) AS customer_count,
        SUM(total_quantity) AS total_quantity_sold,
        SUM(total_sales) AS total_sales_amount
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
    GROUP BY 
        store_name
)
SELECT 
    a.store_name,
    a.customer_count,
    a.total_quantity_sold,
    a.total_sales_amount,
    d.d_year,
    d.d_month_seq,
    CASE 
        WHEN a.total_sales_amount > 5000 THEN 'High Performer'
        WHEN a.total_sales_amount BETWEEN 1000 AND 5000 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    AggregateSales a
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
ORDER BY 
    a.total_sales_amount DESC;
