WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > 1000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_acctbal > 1000 AND ch.level < 5
),
TopSuppliers AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    INNER JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > 50.00
    GROUP BY ps.ps_suppkey
    HAVING total_supply_cost > 10000
),
OrderStatistics AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
NationRevenue AS (
    SELECT n.n_nationkey, n.n_name, COALESCE(SUM(os.total_revenue), 0) AS total_revenue
    FROM nation n
    LEFT JOIN OrderStatistics os ON n.n_nationkey = os.o_orderkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT ch.c_name, SUM(nr.total_revenue) AS total_nation_revenue
FROM CustomerHierarchy ch
JOIN TopSuppliers ts ON ch.c_nationkey = ts.ps_suppkey
JOIN NationRevenue nr ON ch.c_nationkey = nr.n_nationkey
WHERE ch.level < 3 AND ts.total_supply_cost IS NOT NULL
GROUP BY ch.c_name
ORDER BY total_nation_revenue DESC
LIMIT 10;
