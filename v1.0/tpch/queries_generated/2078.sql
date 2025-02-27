WITH TotalSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
SupplierRanked AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS rank_by_cost
    FROM 
        partsupp ps
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(COALESCE(ts.total_revenue, 0)) AS total_sales,
    STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    SupplierRanked sr ON s.s_suppkey = sr.ps_suppkey
LEFT JOIN 
    partsupp ps ON sr.ps_partkey = ps.ps_partkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey AND ps.ps_suppkey = l.l_suppkey
LEFT JOIN 
    TotalSales ts ON l.l_orderkey = ts.l_orderkey
JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
WHERE 
    r.r_name LIKE 'EUROPE%' 
    AND (c.c_acctbal > 1000 OR s.s_acctbal > 1000)
GROUP BY 
    n.n_name, r.r_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_sales DESC, customer_count ASC;
