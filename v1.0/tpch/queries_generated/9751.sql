WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 0 AS level
    FROM customer c
    WHERE c.c_acctbal > 50000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN CustomerHierarchy ch ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND ch.level < 5
),
TopSuppliers AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size > 30
    GROUP BY ps.ps_suppkey
    ORDER BY total_cost DESC
    LIMIT 10
),
NationAggregation AS (
    SELECT n.n_name, COUNT(DISTINCT c.c_custkey) AS num_customers, SUM(o.o_totalprice) AS total_revenue
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN '2022-01-01' AND '2023-12-31'
    GROUP BY n.n_name
)
SELECT ch.c_custkey, ch.c_name, n.n_name, n.num_customers, n.total_revenue, ts.total_cost
FROM CustomerHierarchy ch
JOIN NationAggregation n ON ch.c_nationkey = n.n_nationkey
JOIN TopSuppliers ts ON ch.c_custkey = ts.ps_suppkey
WHERE ch.level = 2
ORDER BY n.total_revenue DESC, ts.total_cost ASC;
