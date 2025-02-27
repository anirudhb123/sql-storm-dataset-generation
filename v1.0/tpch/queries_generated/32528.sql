WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal
),
PartAvailability AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, pa.total_available
    FROM part p
    JOIN PartAvailability pa ON p.p_partkey = pa.ps_partkey
    WHERE p.p_size IN (SELECT DISTINCT p_inner.p_size FROM part p_inner WHERE p_inner.p_retailprice < 50.00)
    ORDER BY pa.total_available DESC
    LIMIT 5
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
)
SELECT nh.n_name, COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
       SUM(ts.total_available) AS total_part_availability,
       os.total_revenue
FROM nation nh
LEFT JOIN SupplierHierarchy sh ON nh.n_nationkey = sh.s_nationkey
LEFT JOIN TopParts ts ON ts.p_partkey IN (SELECT pa.ps_partkey FROM partsupp pa WHERE pa.ps_supkey = sh.s_suppkey)
LEFT JOIN OrderSummary os ON os.rn <= 10
WHERE nh.n_name IS NOT NULL
GROUP BY nh.n_name, os.total_revenue
HAVING SUM(ts.total_available) IS NOT NULL
ORDER BY supplier_count DESC, total_part_availability DESC;
