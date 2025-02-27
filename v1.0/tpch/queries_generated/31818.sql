WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, p.p_size,
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100)
),
OrderAggregates AS (
    SELECT o.o_orderstatus, COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY o.o_orderstatus
)
SELECT r.r_name, n.n_name, s.s_name, COUNT(DISTINCT c.c_custkey) AS customer_count,
       SUM(f.p_retailprice) AS total_parts_value,
       AVG(o.total_revenue) AS average_order_revenue,
       MAX(sh.level) AS max_supplier_level
FROM region r
JOIN nation n ON n.n_regionkey = r.r_regionkey
JOIN supplier s ON s.s_nationkey = n.n_nationkey
JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN FilteredParts f ON f.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost < 500)
LEFT JOIN OrderAggregates o ON o.o_orderstatus = (CASE WHEN s.s_acctbal > 1000 THEN 'O' ELSE 'F' END)
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = s.s_nationkey
GROUP BY r.r_name, n.n_name, s.s_name
HAVING COUNT(DISTINCT c.c_custkey) > 10 AND SUM(f.p_retailprice) IS NOT NULL
ORDER BY total_parts_value DESC, customer_count ASC;
