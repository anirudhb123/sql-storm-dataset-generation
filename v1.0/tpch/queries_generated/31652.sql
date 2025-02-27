WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'GERMANY')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_address, s.nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_suppkey
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
part_supplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty * ps.ps_supplycost) AS total_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size > 10
    GROUP BY ps.ps_partkey
),
ranked_orders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY o.o_orderkey
)
SELECT 
    n.n_name AS nation,
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    COALESCE(po.total_cost, 0) AS part_cost,
    COALESCE(co.total_spent, 0) AS total_spent,
    COUNT(ro.o_orderkey) AS order_count
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN part p ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
LEFT JOIN part_supplier po ON p.p_partkey = po.ps_partkey
LEFT JOIN customer_orders co ON co.c_custkey IN (SELECT DISTINCT o.o_custkey FROM orders o WHERE o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_suppkey = s.s_suppkey))
LEFT JOIN ranked_orders ro ON ro.o_orderkey = o.o_orderkey
WHERE r.r_name IS NOT NULL
GROUP BY n.n_name, s.s_name, p.p_name, po.total_cost, co.total_spent
ORDER BY part_cost DESC, total_spent DESC;
