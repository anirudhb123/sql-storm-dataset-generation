
WITH RECURSIVE TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    INNER JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) IS NOT NULL
),
RankedSuppliers AS (
    SELECT s_suppkey, s_name, TotalSupplyCost, ROW_NUMBER() OVER (ORDER BY TotalSupplyCost DESC) AS Rank
    FROM TopSuppliers
)
SELECT 
    r.r_name AS RegionName,
    n.n_name AS NationName,
    COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END), 0) AS ReturnedSales,
    COUNT(DISTINCT CASE WHEN c.c_mktsegment = 'BUILDING' THEN c.c_custkey END) AS BuildingCustomers,
    STRING_AGG(s.s_name, ', ' ORDER BY s.s_name) AS SupplierNames
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    o.o_orderdate BETWEEN DATE '1990-01-01' AND DATE '1995-12-31'
    AND (c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_mktsegment = c.c_mktsegment) OR c.c_acctbal IS NULL)
GROUP BY 
    r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 1
ORDER BY 
    r.r_name, n.n_name;
