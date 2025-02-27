WITH RECURSIVE OrdersWithPriority AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_orderpriority, o.o_custkey, o.o_totalprice, 1 AS priority_level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_orderdate, o.o_orderpriority, o.o_custkey, o.o_totalprice, ow.priority_level + 1
    FROM orders o
    JOIN OrdersWithPriority ow ON o.o_orderkey > ow.o_orderkey
    WHERE ow.priority_level < 5
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    ORDER BY total_spent DESC
    LIMIT 10
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING total_value > 100000
),
FinalReport AS (
    SELECT 
        tc.c_name,
        tc.total_spent,
        p.p_name AS part_name,
        hp.total_value AS part_value,
        ow.o_orderdate,
        ow.o_orderpriority
    FROM TopCustomers tc
    JOIN HighValueParts hp ON tc.total_spent > 5000
    JOIN OrdersWithPriority ow ON tc.c_custkey = ow.o_custkey
    ORDER BY tc.total_spent DESC, hp.total_value DESC
)
SELECT DISTINCT f.c_name, f.part_name, f.part_value, f.o_orderdate, f.o_orderpriority
FROM FinalReport f
WHERE f.o_orderpriority IN ('HIGH', 'MEDIUM')
ORDER BY f.c_name ASC, f.part_value DESC;
