WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS Level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey IS NOT NULL)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) AND sh.Level < 5
),
TotalOrders AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS order_count
    FROM orders o
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_custkey
),
PartSuppliers AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, pp.total_cost
    FROM part p
    LEFT JOIN PartSuppliers pp ON p.p_partkey = pp.ps_partkey
    WHERE p.p_retialprice IS NOT NULL
),
CustomerOrderTotals AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 0
    GROUP BY c.c_custkey
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, DENSE_RANK() OVER (ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
)
SELECT c.c_name, COUNT(DISTINCT o.o_orderkey) AS num_orders, AVG(o.o_totalprice) AS avg_order_value,
       sh.Level AS supplier_level
FROM customer c
JOIN TotalOrders to ON c.c_custkey = to.o_custkey
JOIN RankedOrders o ON o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_tax IS NOT NULL AND l.l_discount > 0)
JOIN SupplierHierarchy sh ON c.c_nationkey = sh.s_nationkey
WHERE EXISTS (
    SELECT 1
    FROM FilteredParts fp
    WHERE fp.total_cost > 1000
      AND fp.p_retailprice < 500
)
GROUP BY c.c_name, sh.Level
HAVING AVG(o.o_totalprice) > 100
ORDER BY supplier_level DESC, num_orders DESC;
