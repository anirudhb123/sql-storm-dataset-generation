WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, 0 AS level
    FROM customer
    WHERE c_acctbal > (SELECT AVG(c_acctbal) FROM customer)

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE ch.level < 3
),
TotalSales AS (
    SELECT
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING total_supply_cost > (SELECT AVG(total_supply_cost) FROM (
        SELECT SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
        FROM supplier s
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
        GROUP BY s.s_suppkey
    ) as avg_supply)

    ORDER BY total_supply_cost DESC
    LIMIT 5
)
SELECT 
    ch.c_name AS customer_name,
    r.r_name AS region_name,
    ts.total_supply_cost,
    T.total_spent,
    ROW_NUMBER() OVER (PARTITION BY ch.level ORDER BY T.total_spent DESC) AS rn
FROM CustomerHierarchy ch
JOIN nation n ON ch.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN TotalSales T ON ch.c_custkey = T.c_custkey
INNER JOIN TopSuppliers ts ON ts.total_supply_cost > 10000
WHERE T.total_spent IS NOT NULL
ORDER BY ch.level, T.total_spent DESC;
