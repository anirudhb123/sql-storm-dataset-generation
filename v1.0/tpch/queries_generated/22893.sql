WITH RankedSales AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
TopSuppliers AS (
    SELECT 
        ps_partkey,
        ps_suppkey
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
),
CustomerPreferences AS (
    SELECT 
        c.c_custkey,
        c.c_mktsegment,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS preference_rank
    FROM 
        customer c
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name
    FROM 
        CustomerPreferences c
    WHERE 
        c.preference_rank <= 3
)
SELECT 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(COALESCE(l.l_extendedprice, 0) * (1 - COALESCE(l.l_discount, 0))) AS total_revenue,
    AVG(CASE 
        WHEN l.l_shipdate IS NOT NULL THEN DATEDIFF(l.l_shipdate, o.o_orderdate) 
        ELSE NULL 
    END) AS average_shipping_time
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey 
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    HighValueCustomers c ON o.o_custkey = c.c_custkey
WHERE 
    n.r_name NOT LIKE '%land%' AND 
    l.l_returnflag = 'N'
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 0 AND 
    SUM(COALESCE(l.l_extendedprice, 0) * (1 - COALESCE(l.l_discount, 0))) > 10000
ORDER BY 
    total_revenue DESC 
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
