WITH SupplierCost AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerOrderStats AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
HighValueCustomers AS (
    SELECT c.c_custkey
    FROM CustomerOrderStats cos
    JOIN customer c ON cos.c_custkey = c.c_custkey
    WHERE cos.total_spent > (SELECT AVG(total_spent) FROM CustomerOrderStats)
),
PartSupplierDetails AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT p.p_name, ps.total_available, sc.total_supply_cost,
       CASE WHEN hvc.c_custkey IS NOT NULL THEN 'High Value' ELSE 'Regular' END AS customer_type
FROM PartSupplierDetails ps
JOIN SupplierCost sc ON ps.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = sc.s_suppkey)
LEFT JOIN HighValueCustomers hvc ON hvc.c_custkey = (SELECT o.o_custkey 
                                                      FROM orders o 
                                                      JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
                                                      WHERE l.l_partkey = ps.p_partkey
                                                      LIMIT 1)
WHERE ps.total_available IS NOT NULL
ORDER BY ps.total_available DESC, sc.total_supply_cost DESC;
