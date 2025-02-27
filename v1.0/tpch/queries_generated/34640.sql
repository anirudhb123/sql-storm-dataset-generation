WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 0 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderdate = oh.o_orderdate
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
CombinedStats AS (
    SELECT cs.c_custkey, cs.c_name, cs.order_count, cs.total_spent, ss.total_available, ss.avg_supply_cost
    FROM CustomerStats cs
    LEFT JOIN SupplierStats ss ON cs.order_count > 10 AND ss.total_available IS NOT NULL
)
SELECT r.r_name, COUNT(DISTINCT cs.c_custkey) AS unique_customers, AVG(cs.total_spent) AS avg_spent,
       SUM(cs.order_count) FILTER (WHERE cs.order_count > 5) AS high_order_count,
       string_agg(DISTINCT p.p_name, ', ') AS popular_parts
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN CombinedStats cs ON s.s_suppkey = cs.c_custkey
GROUP BY r.r_name
HAVING AVG(cs.total_spent) > (SELECT AVG(total_spent) FROM CombinedStats)
ORDER BY unique_customers DESC, avg_spent DESC;
