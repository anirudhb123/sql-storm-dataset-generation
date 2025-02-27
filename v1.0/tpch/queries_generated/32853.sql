WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal AND sh.level < 3
)

SELECT 
    n.n_name AS Nation,
    p.p_name AS Part,
    COUNT(DISTINCT o.o_orderkey) AS OrderCount,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
    AVG(s.s_acctbal) OVER (PARTITION BY n.n_name) AS AvgSupplierAccountBalance,
    COALESCE(MAX(ps.ps_availqty), 0) AS MaxAvailableQuantity,
    STRING_AGG(DISTINCT s.s_name, ', ') AS SupplierNames,
    CASE 
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000 THEN 'High Revenue'
        ELSE 'Normal Revenue'
    END AS RevenueCategory
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE 
    o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    AND l.l_shipdate <> l.l_commitdate
    AND (p.p_size IS NULL OR p.p_size > 10)
GROUP BY 
    n.n_name, p.p_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    TotalRevenue DESC, Nation;
