WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
),
PartSupplierData AS (
    SELECT ps.ps_partkey,
           SUM(ps.ps_availqty * (1 - ps.ps_supplycost / (SELECT MAX(ps2.ps_supplycost) FROM partsupp ps2 WHERE ps2.ps_partkey = ps.ps_partkey))) AS adjusted_availqty,
           ps.ps_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT p.p_partkey,
       p.p_name,
       psd.adjusted_availqty,
       CASE 
           WHEN psd.adjusted_availqty IS NULL THEN 'Not Available'
           ELSE 'Available'
       END AS availability_status,
       SUM(lo.l_extendedprice) AS total_extended_price,
       r.r_name AS region
FROM part p
LEFT JOIN PartSupplierData psd ON p.p_partkey = psd.ps_partkey
LEFT JOIN lineitem lo ON p.p_partkey = lo.l_partkey
JOIN nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = lo.l_orderkey)
JOIN region r ON r.r_regionkey = n.n_regionkey
WHERE EXISTS (SELECT 1 FROM SupplierHierarchy sh WHERE sh.s_nationkey = n.n_nationkey)
GROUP BY p.p_partkey, p.p_name, psd.adjusted_availqty, r.r_name
HAVING SUM(lo.l_extendedprice) > 10000 AND MAX(psd.ps_supplycost) IS NOT NULL
ORDER BY total_extended_price DESC;
