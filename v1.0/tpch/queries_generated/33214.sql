WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS depth
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.depth + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
CustomerOrderDetails AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
)
SELECT r.r_name, 
       COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
       SUM(COALESCE(cod.o_totalprice, 0)) AS total_order_value,
       AVG(COALESCE(cod.o_totalprice, 0)) AS avg_order_value,
       STRING_AGG(DISTINCT p.p_name, ', ') AS product_names
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN lineitem l ON l.l_suppkey = sh.s_suppkey
LEFT JOIN CustomerOrderDetails cod ON cod.o_orderkey = l.l_orderkey
LEFT JOIN part p ON p.p_partkey = l.l_partkey
WHERE (s.s_acctbal IS NOT NULL OR sh.depth > 0)
GROUP BY r.r_name
HAVING COUNT(DISTINCT sh.s_suppkey) > 5;
