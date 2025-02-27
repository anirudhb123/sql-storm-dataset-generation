
WITH RECURSIVE SalesCTE AS (
    SELECT 
        w.warehouse_id,
        w.warehouse_name,
        SUM(ss_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions
    FROM 
        warehouse w
    JOIN 
        store s ON w.warehouse_sk = s.s_store_sk
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        w.warehouse_id, w.warehouse_name
    UNION ALL
    SELECT 
        w.warehouse_id,
        w.warehouse_name,
        SUM(ss_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions
    FROM 
        warehouse w
    JOIN 
        store s ON w.warehouse_sk = s.s_store_sk
    JOIN 
        store_returns sr ON s.s_store_sk = sr.sr_store_sk
    WHERE 
        sr_returned_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        w.warehouse_id, w.warehouse_name
),
RankedSales AS (
    SELECT 
        warehouse_id,
        warehouse_name,
        total_sales,
        total_transactions,
        RANK() OVER (ORDER BY total_sales DESC) AS rank_sales,
        RANK() OVER (ORDER BY total_transactions DESC) AS rank_transactions
    FROM 
        SalesCTE
)
SELECT 
    rs.warehouse_id,
    rs.warehouse_name,
    COALESCE(rs.total_sales, 0) AS total_sales,
    COALESCE(rs.total_transactions, 0) AS total_transactions,
    CASE 
        WHEN rs.total_sales > 100000 THEN 'High Sales'
        WHEN rs.total_sales > 50000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    RankedSales rs
LEFT JOIN 
    customer c ON c.c_current_addr_sk IS NULL 
WHERE 
    (rs.total_transactions IS NULL OR rs.total_transactions > 0)
    AND (c.c_customer_sk IS NOT NULL OR c.c_customer_id IS NOT NULL)
ORDER BY 
    rs.rank_sales, rs.rank_transactions
LIMIT 10;
