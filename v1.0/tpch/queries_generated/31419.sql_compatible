
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_comment, 1 AS lvl
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, sh.lvl + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal > sh.s_acctbal
), OrderSummary AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
), SupplierMaterials AS (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT
    n.n_name AS nation,
    p.p_mfgr AS manufacturer,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(os.total_revenue) AS max_revenue,
    AVG(NULLIF(s.s_acctbal, 0)) AS avg_supplier_balance,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ': ', s.s_comment), '; ') AS supplier_info
FROM nation n
JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON p.p_partkey = ps.ps_partkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN OrderSummary os ON os.o_orderkey = l.l_orderkey
JOIN orders o ON o.o_orderkey = l.l_orderkey
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
AND l.l_shipmode IN ('AIR', 'TRUCK')
GROUP BY n.n_name, p.p_mfgr
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_orders DESC, max_revenue DESC;
