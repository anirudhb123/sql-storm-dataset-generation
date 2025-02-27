WITH RECURSIVE HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
    FROM supplier s
    INNER JOIN HighValueSuppliers h ON s.s_suppkey = h.s_suppkey
    WHERE s.s_acctbal > 0
),
PartSupplierCounts AS (
    SELECT ps.ps_partkey, COUNT(ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
OrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    p.p_type,
    COALESCE(ps.supplier_count, 0) AS supplier_count,
    AVG(o.total_revenue) AS average_revenue,
    COUNT(DISTINCT ns.n_nationkey) AS nation_count,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM part p
LEFT JOIN PartSupplierCounts ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN nation ns ON s.s_nationkey = ns.n_nationkey
WHERE p.p_retailprice > 50.00
GROUP BY p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type
HAVING AVG(o.total_revenue) IS NOT NULL
ORDER BY average_revenue DESC
LIMIT 100;
