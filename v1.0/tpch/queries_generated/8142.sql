WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 1000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
TopSuppliers AS (
    SELECT sh.s_suppkey, sh.s_name, sh.level, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM SupplierHierarchy sh
    JOIN partsupp ps ON ps.ps_suppkey = sh.s_suppkey
    GROUP BY sh.s_suppkey, sh.s_name, sh.level
    ORDER BY total_cost DESC
    LIMIT 5
)
SELECT
    c.c_name AS customer_name,
    o.o_orderkey AS order_id,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
    n.n_name AS nation_name,
    rh.total_cost AS supplier_total_cost
FROM orders o
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN TopSuppliers rh ON s.s_suppkey = rh.s_suppkey
WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY c.c_name, o.o_orderkey, n.n_name, rh.total_cost
HAVING total_order_value > 10000
ORDER BY total_order_value DESC, customer_name ASC;
