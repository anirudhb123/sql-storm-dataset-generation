
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS unique_sales_count,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        d.d_year,
        d.d_month_seq,
        w.w_warehouse_name
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN 
        warehouse w ON ss.ss_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        c.c_customer_id, ca.ca_city, d.d_year, d.d_month_seq, w.w_warehouse_name
),
avg_sales AS (
    SELECT 
        ca_city,
        d_year,
        d_month_seq,
        AVG(total_sales) AS avg_total_sales
    FROM 
        sales_summary
    GROUP BY 
        ca_city, d_year, d_month_seq
)
SELECT 
    a.ca_city,
    a.d_year,
    a.d_month_seq,
    a.avg_total_sales,
    COUNT(DISTINCT ss.c_customer_id) AS total_customers,
    SUM(a.avg_total_sales) AS combined_avg_sales
FROM 
    avg_sales a
JOIN 
    sales_summary ss ON a.ca_city = ss.ca_city 
    AND a.d_year = ss.d_year 
    AND a.d_month_seq = ss.d_month_seq
GROUP BY 
    a.ca_city, a.d_year, a.d_month_seq
ORDER BY 
    a.d_year, a.d_month_seq, a.ca_city;
