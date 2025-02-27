WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_address, s.nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_name
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
),
PartSuppSummary AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(sh.level, 0) AS supplier_level,
    hvo.o_totalprice,
    hvo.o_orderdate,
    pss.total_avail_qty,
    pss.supplier_count
FROM part p
LEFT JOIN SupplierHierarchy sh ON p.p_partkey = sh.s_suppkey
LEFT JOIN HighValueOrders hvo ON hvo.o_orderkey = (SELECT MAX(o.o_orderkey) FROM orders o WHERE o.o_orderdate < CURRENT_DATE)
JOIN PartSuppSummary pss ON p.p_partkey = pss.ps_partkey
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
ORDER BY p.p_retailprice DESC, hvo.o_totalprice ASC
LIMIT 50;
