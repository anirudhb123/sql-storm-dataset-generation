WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT ps.ps_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal < (SELECT AVG(s_acctbal) FROM supplier)
),

OrderStats AS (
    SELECT o.o_orderkey, 
           COUNT(l.l_linenumber) AS line_count, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS returns
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),

MaxRevenue AS (
    SELECT MAX(total_revenue) AS max_revenue
    FROM OrderStats
),

ColoredRegions AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_name
)

SELECT 
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    COALESCE(sh.level, 0) AS supplier_level,
    o.line_count,
    o.total_revenue,
    o.returns,
    cr.nation_count
FROM part p
LEFT JOIN SupplierHierarchy sh ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sh.s_suppkey)
JOIN OrderStats o ON p.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE o.o_orderkey = l.l_orderkey)
LEFT JOIN ColoredRegions cr ON cr.nation_count > (SELECT COUNT(*) FROM nation) / 2
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
AND o.total_revenue > (SELECT max_revenue FROM MaxRevenue)
ORDER BY o.total_revenue DESC, p.p_name;
