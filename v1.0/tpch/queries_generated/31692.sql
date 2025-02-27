WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 0 AS level
    FROM customer c
    WHERE c.c_acctbal > 10000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_acctbal > 5000
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_totalprice, COUNT(DISTINCT l.l_orderkey) AS total_lines,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderstatus <> 'F'
    GROUP BY o.o_orderkey, o.o_totalprice
)
SELECT 
    n.n_name AS nation_name,
    SUM(COALESCE(os.net_revenue, 0)) AS total_revenue,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    COUNT(DISTINCT ts.s_suppkey) AS total_top_suppliers
FROM nation n
LEFT JOIN CustomerHierarchy ch ON n.n_nationkey = ch.c_nationkey
LEFT JOIN OrderSummary os ON os.o_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_custkey = ch.c_custkey
)
LEFT JOIN TopSuppliers ts ON ts.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o
        WHERE o.o_custkey = ch.c_custkey
    )
)
GROUP BY n.n_name
ORDER BY total_revenue DESC
LIMIT 10;
