WITH RECURSIVE sales_data AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY 
        c.c_custkey
),
top_customers AS (
    SELECT 
        c.c_name, 
        c.c_acctbal, 
        sd.total_sales
    FROM 
        sales_data sd
    JOIN 
        customer c ON sd.c_custkey = c.c_custkey
    WHERE 
        sd.sales_rank <= 10
)
SELECT 
    tc.c_name,
    tc.c_acctbal,
    COALESCE(NULLIF(tc.total_sales, 0), 'No sales') AS total_sales,
    RANK() OVER (ORDER BY tc.total_sales DESC) AS sales_rank,
    CASE 
        WHEN tc.total_sales IS NOT NULL AND tc.total_sales > 10000 THEN 'High'
        WHEN tc.total_sales IS NULL OR tc.total_sales <= 1000 THEN 'Low'
        ELSE 'Medium'
    END AS sales_category
FROM 
    top_customers tc
LEFT JOIN 
    supplier s ON s.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        JOIN part p ON ps.ps_partkey = p.p_partkey
        WHERE p.p_type LIKE 'type%'
    )
WHERE 
    tc.c_acctbal > 5000
ORDER BY 
    sales_rank;
