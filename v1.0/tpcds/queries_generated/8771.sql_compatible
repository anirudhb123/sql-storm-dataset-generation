
WITH sales_summary AS (
    SELECT 
        d.d_year,
        SUM(ss.sales_price) AS total_sales,
        COUNT(DISTINCT ss.ticket_number) AS total_transactions,
        AVG(ss.sales_price) AS avg_sales_price,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers
    FROM 
        store_sales ss
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year
), return_summary AS (
    SELECT 
        d.d_year,
        SUM(sr.return_amt) AS total_returns,
        COUNT(sr.return_quantity) AS total_return_transactions,
        AVG(sr.return_amt) AS avg_return_amount
    FROM 
        store_returns sr
    JOIN 
        date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year
)

SELECT 
    ss.d_year,
    ss.total_sales,
    ss.total_transactions,
    ss.avg_sales_price,
    ss.unique_customers,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_transactions, 0) AS total_return_transactions,
    COALESCE(rs.avg_return_amount, 0) AS avg_return_amount,
    (ss.total_sales - COALESCE(rs.total_returns, 0)) AS net_sales
FROM 
    sales_summary ss
LEFT JOIN 
    return_summary rs ON ss.d_year = rs.d_year
ORDER BY 
    ss.d_year;
