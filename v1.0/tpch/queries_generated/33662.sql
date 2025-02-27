WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_nationkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) IS NOT NULL
    ORDER BY total_supply_cost DESC
    LIMIT 10
),
CustomerOrderStats AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT ph.n_name AS nation, ts.s_name AS supplier, cos.order_count, cos.total_spent
FROM TopSuppliers ts
JOIN CustomerOrderStats cos ON cos.total_spent IS NOT NULL
FULL OUTER JOIN NationHierarchy ph ON ph.n_nationkey = ts.s_suppkey
WHERE ph.level <= 3
ORDER BY cos.order_count DESC, ts.total_supply_cost DESC;
