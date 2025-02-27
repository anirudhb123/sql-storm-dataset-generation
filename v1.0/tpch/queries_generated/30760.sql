WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
ProductAvailability AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > (SELECT AVG(ps_availqty) FROM partsupp)
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
),
AggregatedData AS (
    SELECT sh.s_nationkey, COUNT(DISTINCT sh.s_suppkey) AS supplier_count, 
           SUM(sh.s_acctbal) AS total_acctbal,
           AVG(COALESCE(pa.ps_supplycost, 0)) AS avg_supplycost
    FROM SupplierHierarchy sh
    LEFT JOIN ProductAvailability pa ON sh.s_nationkey = pa.p_partkey
    GROUP BY sh.s_nationkey
)
SELECT n.n_name, ad.supplier_count, ad.total_acctbal, ad.avg_supplycost
FROM AggregatedData ad
JOIN nation n ON ad.s_nationkey = n.n_nationkey
WHERE ad.supplier_count > 5
ORDER BY ad.total_acctbal DESC
LIMIT 10;
