WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = ch.c_custkey)
    WHERE c.c_acctbal IS NOT NULL
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT c.c_custkey) AS unique_customers
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
TopRevenue AS (
    SELECT DISTINCT o.o_orderdate, o.total_revenue
    FROM OrderStats o
    WHERE o.total_revenue > 100000
),
NationSupplier AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT rh.level,
       COALESCE(ns.n_name, 'Unknown Region') AS nation_name,
       COUNT(DISTINCT c.c_custkey) AS total_customers,
       SUM(COALESCE(ts.total_revenue, 0)) AS total_revenue_generated,
       AVG(s.s_acctbal) AS average_supplier_acctbal
FROM CustomerHierarchy c
LEFT JOIN TopRevenue ts ON c.c_custkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderdate >= '2023-01-01')
LEFT JOIN NationSupplier ns ON c.c_custkey = ns.supplier_count
LEFT JOIN supplier s ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#1'))
GROUP BY rh.level, ns.n_name
ORDER BY total_revenue_generated DESC, rh.level ASC;
