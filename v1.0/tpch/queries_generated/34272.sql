WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_acctbal > sh.s_acctbal
),
part_supplier_summary AS (
    SELECT p.p_partkey, p.p_name, 
           SUM(ps.ps_availqty) AS total_available, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
order_stats AS (
    SELECT o.o_orderkey, o.o_orderdate, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_linenumber) AS line_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
nations_with_regions AS (
    SELECT n.n_name, r.r_name,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name, r.r_name
)
SELECT 
    p.p_partkey, p.p_name,
    ph.s_name AS supplier_name,
    COALESCE(order_stats.total_revenue, 0) AS total_revenue,
    ns.region_name,
    (SELECT AVG(total_available) FROM part_supplier_summary) AS avg_avail_qty,
    COUNT(DISTINCT ns.n_name) AS total_nations
FROM part p
LEFT JOIN part_supplier_summary ps ON p.p_partkey = ps.p_partkey
LEFT JOIN supplier_hierarchy ph ON ph.s_suppkey = (SELECT ps_suppkey FROM partsupp WHERE ps_partkey = p.p_partkey LIMIT 1)
LEFT JOIN nations_with_regions ns ON ns.supplier_count > 5
LEFT JOIN order_stats ON order_stats.total_revenue > 10000
WHERE p.p_size IS NOT NULL
GROUP BY p.p_partkey, p.p_name, ph.s_name, order_stats.total_revenue, ns.region_name
HAVING SUM(ps.total_cost) > (SELECT SUM(ps.total_cost) / COUNT(*) FROM part_supplier_summary)
ORDER BY total_revenue DESC, p.p_name;
