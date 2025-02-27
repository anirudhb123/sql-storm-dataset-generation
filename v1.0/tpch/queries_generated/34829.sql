WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
recent_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
    WHERE o.o_orderdate >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
),
top_customers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           RANK() OVER (ORDER BY SUM(ro.total_amount) DESC) AS rnk
    FROM customer c
    JOIN recent_orders ro ON c.c_custkey = ro.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
    HAVING rnk <= 10
)
SELECT n.n_name, r.r_name, 
       COUNT(DISTINCT s.s_suppkey) AS supplier_count,
       SUM(COALESCE(ps.ps_availqty, 0)) AS total_availability,
       AVG(ps.ps_supplycost) AS avg_supply_cost
FROM nation n
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN top_customers tc ON s.s_nationkey = tc.c_custkey
GROUP BY n.n_name, r.r_name
HAVING total_availability > 0
ORDER BY n.n_name, avg_supply_cost DESC;
