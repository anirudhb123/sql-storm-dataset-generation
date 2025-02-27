WITH RankedSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
),
AvailableParts AS (
    SELECT p.p_partkey,
           p.p_name,
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS average_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT c.c_custkey,
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT DISTINCT r.r_name,
                p.p_name,
                COALESCE(ps.total_available, 0) AS available_qty,
                COALESCE(ps.average_cost, 0) AS avg_cost,
                CASE
                    WHEN co.order_count IS NULL THEN 'No Orders'
                    ELSE CONCAT('Ordered ', co.order_count, ' times, Total spent: $', ROUND(co.total_spent, 2))
                END AS customer_order_info
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey
LEFT JOIN AvailableParts ps ON ps.total_available > 100
LEFT JOIN CustomerOrders co ON co.order_count > 5
WHERE rs.rn = 1
  AND (rs.s_name LIKE '%Supplier%' OR rs.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier s2 WHERE s2.n_nationkey = n.n_nationkey))
ORDER BY r.r_name, available_qty DESC, avg_cost ASC;
