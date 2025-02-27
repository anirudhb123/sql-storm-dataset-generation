WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1 AS level
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY o.o_orderkey
),
CustomerOrderCount AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
PartSupplier AS (
    SELECT p.p_partkey, SUM(ps.ps_availqty) AS total_avail_qty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > 100.00
    GROUP BY p.p_partkey
)
SELECT 
    n.n_name AS nation_name,
    COALESCE(SUM(od.total_price), 0) AS total_order_value,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    COUNT(DISTINCT p.p_partkey) AS unique_parts,
    MAX(sh.level) AS max_supplier_level
FROM nation n
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN OrderDetails od ON o.o_orderkey = od.o_orderkey
LEFT JOIN PartSupplier ps ON ps.p_partkey = n.n_nationkey
LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
GROUP BY n.n_name
HAVING SUM(od.total_price) > 10000 OR COUNT(DISTINCT c.c_custkey) > 10
ORDER BY total_order_value DESC, unique_customers ASC;
