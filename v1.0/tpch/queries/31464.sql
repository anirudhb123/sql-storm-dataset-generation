
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_address, s_nationkey, s_acctbal, s_comment, 1 AS Level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal, s.s_comment, sh.Level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
)

SELECT 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS CustomerCount,
    SUM(o.o_totalprice) AS TotalRevenue,
    AVG(l.l_discount) AS AvgDiscountRate,
    STRING_AGG(DISTINCT p.p_name, ', ') AS Products,
    COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END), 0) AS TotalReturns
FROM 
    region r
INNER JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    r.r_name IN ('AMERICA', 'EUROPE')
    AND o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5
ORDER BY 
    TotalRevenue DESC;
