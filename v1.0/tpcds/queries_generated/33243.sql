
WITH RECURSIVE SalesData AS (
    SELECT 
        ss.s_sold_date_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d) - 30
    GROUP BY 
        ss.s_sold_date_sk
    
    UNION ALL
    
    SELECT 
        d.d_date_sk,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_sales,
        COALESCE(COUNT(ss.ss_ticket_number), 0) AS total_transactions
    FROM 
        date_dim d
    LEFT JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    WHERE 
        d.d_date_sk < (SELECT MIN(s.s_sold_date_sk) FROM store_sales s WHERE s.ss_sold_date_sk >= (SELECT MAX(d2.d_date_sk) FROM date_dim d2) - 30)
    GROUP BY 
        d.d_date_sk
),
RankedSales AS (
    SELECT 
        sd.s_sold_date_sk,
        sd.total_sales,
        sd.total_transactions,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM d.d_date) ORDER BY sd.total_sales DESC) AS yearly_rank
    FROM 
        SalesData sd
    JOIN 
        date_dim d ON sd.s_sold_date_sk = d.d_date_sk
)
SELECT 
    dd.d_date,
    COALESCE(rs.total_sales, 0) AS total_sales,
    COALESCE(rs.total_transactions, 0) AS total_transactions,
    rs.sales_rank,
    rs.yearly_rank
FROM 
    date_dim dd
LEFT JOIN 
    RankedSales rs ON dd.d_date_sk = rs.s_sold_date_sk
WHERE 
    dd.d_year = EXTRACT(YEAR FROM CURRENT_DATE)
ORDER BY 
    dd.d_date;
