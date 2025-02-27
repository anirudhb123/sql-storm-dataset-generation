WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
part_stats AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spending
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
region_summary AS (
    SELECT n.n_regionkey, r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_balance
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_regionkey, r.r_name
)
SELECT 
    r.r_name, 
    ps.p_name, 
    ps.total_available, 
    ps.avg_supply_cost, 
    ps.unique_suppliers,
    co.total_orders, 
    co.total_spending,
    COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity END), 0) AS total_returned
FROM part_stats ps
JOIN lineitem l ON ps.p_partkey = l.l_partkey
JOIN customer_orders co ON co.total_orders > 0
JOIN region_summary r ON r.supplier_count > 10
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = (SELECT n.n_nationkey 
                                                       FROM nation n 
                                                       WHERE n.n_name = 'USA')
GROUP BY r.r_name, ps.p_name, ps.total_available, ps.avg_supply_cost, 
         ps.unique_suppliers, co.total_orders, co.total_spending
HAVING ps.total_available > 100 
   OR co.total_spending > 5000
ORDER BY r.r_name, ps.p_name;
