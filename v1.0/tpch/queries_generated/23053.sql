WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment, 
           1 AS level 
    FROM supplier 
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
    UNION ALL 
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, 
           sh.level + 1 
    FROM supplier s 
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey 
    WHERE sh.level < 5
), 
part_supplier_stats AS (
    SELECT p.p_partkey, COUNT(ps.ps_suppkey) AS total_suppliers,
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           SUM(CASE WHEN ps.ps_availqty < 100 THEN 1 ELSE 0 END) AS low_avail_count
    FROM part p 
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey 
    GROUP BY p.p_partkey
),
order_analysis AS (
    SELECT o.o_orderkey, o.o_orderstatus, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_linenumber) AS line_count
    FROM orders o 
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
    WHERE l.l_returnflag = 'N' 
    GROUP BY o.o_orderkey, o.o_orderstatus
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, 
           SUM(o.o_totalprice) AS total_spent, 
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c 
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey 
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.r_name, 
       COUNT(DISTINCT ns.n_nationkey) AS nation_count,
       SUM(ps.avg_supply_cost) AS total_avg_supply_cost,
       AVG(cs.total_spent) AS avg_customer_spent,
       MAX(o.total_revenue) as max_order_revenue
FROM region r 
JOIN nation ns ON r.r_regionkey = ns.n_regionkey 
LEFT JOIN part_supplier_stats ps ON ps.total_suppliers > 5 
LEFT JOIN customer_summary cs ON cs.total_spent IS NOT NULL 
LEFT JOIN order_analysis o ON o.line_count > 2 AND o.total_revenue > 1000 
WHERE r.r_comment IS NOT NULL 
GROUP BY r.r_name 
HAVING SUM(CASE WHEN ps.low_avail_count > 0 THEN 1 ELSE 0 END) > 0 
   OR EXISTS (SELECT 1 FROM supplier_hierarchy sh WHERE sh.level > 3)
ORDER BY nation_count DESC, avg_customer_spent DESC 
LIMIT 10;
