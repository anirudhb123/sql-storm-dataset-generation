WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, COUNT(p.ps_supplycost) AS supply_count, 
           SUM(p.ps_supplycost) AS total_supply_cost,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(p.ps_supplycost) DESC) AS rn
    FROM supplier s
    JOIN partsupp p ON s.s_suppkey = p.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
PopularParts AS (
    SELECT p.p_partkey, p.p_name, COUNT(l.l_orderkey) AS order_count
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING COUNT(l.l_orderkey) > 5
),
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    rs.s_name AS supplier_name,
    pp.p_name AS popular_part,
    cos.c_name AS customer_name,
    cos.total_orders,
    cos.total_spent,
    rs.total_supply_cost
FROM RankedSuppliers rs
JOIN PopularParts pp ON rs.s_suppkey IN (
    SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (
        SELECT p.p_partkey FROM part p WHERE p.p_name LIKE '%steel%'
    )
)
JOIN CustomerOrderStats cos ON cos.total_orders > 10
WHERE rs.rn = 1
ORDER BY rs.total_supply_cost DESC, cos.total_spent DESC
LIMIT 10;
