WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    UNION ALL
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) + co.total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN CustomerOrders co ON co.c_custkey = c.c_custkey
    WHERE co.total_spent < 1000
    GROUP BY c.c_custkey, c.c_name
),
AggregatedSuppliers AS (
    SELECT s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey
),
PartStatistics AS (
    SELECT p.p_partkey, p.p_name, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           AVG(ps.ps_availqty) AS avg_availability,
           MAX(p.p_retailprice) AS max_price
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    c.c_name,
    COALESCE(co.total_spent, 0) AS total_spent,
    p.p_name,
    ps.supplier_count,
    ps.avg_availability,
    ps.max_price,
    rs.r_name,
    rs.total_supply_cost
FROM CustomerOrders co
JOIN PartStatistics ps ON co.c_custkey = ps.p_partkey
LEFT JOIN AggregatedSuppliers rs ON ps.supplier_count = rs.s_nationkey
WHERE rs.total_supply_cost IS NOT NULL
  AND co.total_spent BETWEEN 100 AND 10000
ORDER BY total_spent DESC, ps.max_price ASC;
