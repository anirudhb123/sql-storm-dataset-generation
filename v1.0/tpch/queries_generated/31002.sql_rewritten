WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 10000
    
    UNION ALL
    
    SELECT ps.ps_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON ps.ps_partkey = sh.s_suppkey
    JOIN supplier s ON s.s_suppkey = ps.ps_suppkey
)
SELECT
    n.n_name AS nation_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(SH.level) AS supplier_level,
    RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM
    nation n
LEFT JOIN
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN
    part p ON ps.ps_partkey = p.p_partkey
JOIN
    lineitem l ON l.l_partkey = p.p_partkey
JOIN
    orders o ON o.o_orderkey = l.l_orderkey
JOIN
    SupplierHierarchy SH ON SH.s_suppkey = s.s_suppkey
WHERE 
    o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1997-01-01'
    AND (s.s_acctbal IS NULL OR s.s_acctbal > 5000)
GROUP BY
    n.n_name
ORDER BY
    total_revenue DESC, n.n_name ASC
LIMIT 10;