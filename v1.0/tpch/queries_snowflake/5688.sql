WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT RANK() OVER (PARTITION BY s_nationkey ORDER BY total_cost DESC) AS rank, s_suppkey, s_name
    FROM RankedSuppliers
),
CustomerStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
FinalResults AS (
    SELECT cs.c_custkey, cs.c_name, ts.s_name AS top_supplier, cs.total_spent, cs.order_count
    FROM CustomerStats cs
    JOIN TopSuppliers ts ON cs.c_custkey = (SELECT c.c_custkey
                                             FROM customer c
                                             JOIN orders o ON c.c_custkey = o.o_custkey
                                             WHERE o.o_orderstatus = 'F' AND ts.rank = 1
                                             LIMIT 1)
)
SELECT fr.c_custkey, fr.c_name, fr.top_supplier, fr.total_spent, fr.order_count
FROM FinalResults fr
WHERE fr.total_spent > (SELECT AVG(total_spent) FROM CustomerStats)
AND fr.order_count > (SELECT AVG(order_count) FROM CustomerStats)
ORDER BY fr.total_spent DESC, fr.order_count DESC;
