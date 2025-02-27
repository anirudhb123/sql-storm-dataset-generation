
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT ps.ps_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON ps.ps_partkey = sh.s_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(sh.s_acctbal) AS avg_supplier_acctbal,
    ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM 
    nation n
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierHierarchy sh ON c.c_nationkey = (SELECT n.n_nationkey FROM supplier s JOIN nation n ON s.s_nationkey = n.n_nationkey WHERE s.s_suppkey = sh.s_suppkey)
WHERE 
    l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    AND (o.o_orderstatus = 'F' OR o.o_orderstatus IS NULL)
GROUP BY 
    n.n_name, n.n_nationkey
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000000
ORDER BY 
    customer_count DESC, avg_supplier_acctbal DESC;
