
SELECT 
    SUM(ss.ext_sales_price) AS total_sales,
    COUNT(DISTINCT ss.customer_sk) AS unique_customers,
    COUNT(ss.ticket_number) AS total_transactions,
    AVG(ss.net_paid) AS avg_sales_per_transaction,
    DATE(d.date) AS sales_date
FROM 
    store_sales AS ss
JOIN 
    date_dim AS d ON ss.sold_date_sk = d.date_sk
WHERE 
    d.year = 2023
GROUP BY 
    DATE(d.date)
ORDER BY 
    sales_date;
