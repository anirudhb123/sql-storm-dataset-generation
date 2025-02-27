WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
    HAVING SUM(li.l_extendedprice * (1 - li.l_discount)) > 1000
)
SELECT r.r_name, COUNT(DISTINCT c.c_custkey) AS total_customers,
       AVG(cs.total_orders) AS avg_orders, MAX(cs.total_spent) AS max_spent,
       MIN(sh.level) AS min_supplier_level, SUM(ps.total_supply_cost) AS total_part_cost
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN CustomerOrders cs ON c.c_custkey = cs.c_custkey
LEFT JOIN PartSupplier ps ON ps.p_partkey IN (
    SELECT p.p_partkey
    FROM part p
    WHERE p.p_size BETWEEN 10 AND 20
)
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
GROUP BY r.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 0
ORDER BY total_customers DESC, r.r_name ASC;
