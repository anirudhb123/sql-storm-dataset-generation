WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, COUNT(ps.ps_suppkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, r.r_name, s.s_acctbal
    FROM RankedSuppliers r
    JOIN supplier s ON r.s_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE r.r_name = 'Asia'
    ORDER BY r.part_count DESC
    LIMIT 10
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT ts.s_name, ts.s_acctbal, co.c_name, co.total_spent
FROM TopSuppliers ts
JOIN CustomerOrders co ON ts.s_nationkey = co.c_nationkey
WHERE ts.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
ORDER BY co.total_spent DESC, ts.s_name ASC;
