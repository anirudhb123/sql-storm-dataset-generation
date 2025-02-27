WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, ARRAY[s_suppkey] AS path
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT ps.s_suppkey, s.s_name, s.s_acctbal, s.nationkey, path || ps.s_suppkey
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
)

SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(SH.s_acctbal) AS avg_supplier_balance,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN SupplierHierarchy SH ON s.s_suppkey = SH.s_suppkey
WHERE l.l_shipdate >= '2023-01-01' 
    AND l.l_shipdate < '2024-01-01'
    AND (l.l_returnflag IS NULL OR l.l_returnflag = 'N')
GROUP BY n.n_name
HAVING COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY total_revenue DESC;
