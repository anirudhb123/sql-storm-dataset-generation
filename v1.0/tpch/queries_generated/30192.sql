WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 50000 AND sh.level < 5
),
RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank,
           COUNT(*) OVER (PARTITION BY p.p_type) AS total_count
    FROM part p
    WHERE p.p_size = (SELECT MAX(p2.p_size) FROM part p2)
),
TotalOrders AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) AS total_spent
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE c.c_mktsegment = 'BUILDING'
    GROUP BY o.o_custkey
),
SupplierParts AS (
    SELECT s.s_name, ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_name, ps.ps_partkey
)
SELECT sh.s_name, 
       rp.p_name, 
       rp.p_retailprice, 
       COALESCE(tp.total_spent, 0) AS total_spent, 
       sp.total_avail,
       CASE WHEN rp.rank <= 3 THEN 'Top Price' ELSE 'Other' END AS price_category
FROM SupplierHierarchy sh
LEFT JOIN RankedParts rp ON rp.p_partkey IN (SELECT ps.ps_partkey FROM SupplierParts sp WHERE sp.s_name = sh.s_name)
LEFT JOIN TotalOrders tp ON tp.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = sh.s_nationkey)
LEFT JOIN SupplierParts sp ON sp.total_avail > 100
WHERE sh.level = 1 AND rp.rank = 1 OR rp.rank = 2 OR rp.rank = 3
ORDER BY sh.s_name, rp.p_retailprice DESC;
