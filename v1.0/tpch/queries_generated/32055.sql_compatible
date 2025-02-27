
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 1 AS level 
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           RANK() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_size < 20
),
OrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_orderkey) AS line_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
)
SELECT n.n_name AS nation_name,
       COUNT(DISTINCT o.o_orderkey) AS order_count,
       SUM(ps.ps_availqty) AS total_available_qty,
       AVG(sp.level) AS avg_supplier_level,
       STRING_AGG(DISTINCT CONCAT('Part: ', rp.p_name, ' (Price: ', rp.p_retailprice, ')'), ', ') AS parts_info
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN RankedParts rp ON ps.ps_partkey = rp.p_partkey AND rp.price_rank <= 3
LEFT JOIN OrderStats o ON o.o_orderkey = (
    SELECT o2.o_orderkey
    FROM orders o2
    WHERE o2.o_orderstatus = 'O'
    ORDER BY o2.o_orderdate DESC
    LIMIT 1
)
LEFT JOIN SupplierHierarchy sp ON s.s_suppkey = sp.s_suppkey
WHERE ps.ps_availqty IS NOT NULL AND ps.ps_supplycost < 20
GROUP BY n.n_name, sp.level
HAVING COUNT(DISTINCT o.o_orderkey) > 0
ORDER BY order_count DESC;
