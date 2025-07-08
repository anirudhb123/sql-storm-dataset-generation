
WITH MonthlySales AS (
    SELECT 
        d.d_month_seq,
        SUM(ss.ss_net_paid) AS total_sales
    FROM 
        date_dim d
    JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_month_seq
    UNION ALL
    SELECT 
        ms.d_month_seq,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_sales
    FROM 
        MonthlySales ms
    JOIN 
        date_dim d ON d.d_month_seq = ms.d_month_seq - 1
    LEFT JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ms.d_month_seq
),
SalesWithRanking AS (
    SELECT 
        d.d_month_seq,
        SUM(ss.ss_net_paid) AS monthly_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(ss.ss_net_paid) DESC) AS sales_rank
    FROM 
        date_dim d
    JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_month_seq
)
SELECT 
    d.d_month_seq,
    COALESCE(ms.total_sales, 0) AS recursive_sales,
    swr.monthly_sales,
    swr.sales_rank,
    CASE 
        WHEN swr.monthly_sales IS NULL THEN 'No Sales'
        WHEN swr.monthly_sales < 1000 THEN 'Low Sales'
        WHEN swr.monthly_sales BETWEEN 1000 AND 5000 THEN 'Moderate Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM 
    date_dim d
LEFT JOIN 
    MonthlySales ms ON d.d_month_seq = ms.d_month_seq
LEFT JOIN 
    SalesWithRanking swr ON d.d_month_seq = swr.d_month_seq
WHERE 
    d.d_year = 2023
ORDER BY 
    d.d_month_seq;
