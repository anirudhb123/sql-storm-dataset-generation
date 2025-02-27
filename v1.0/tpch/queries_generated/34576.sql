WITH RECURSIVE nation_hierarchy AS (
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, 1 AS depth
    FROM nation n
    WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA')
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.depth + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
supplier_summary AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           COUNT(DISTINCT ps.ps_partkey) AS total_parts,
           SUM(ps.ps_availqty) AS total_available_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY s.s_suppkey, s.s_name
),
order_summary AS (
    SELECT o.o_orderkey, 
           o.o_custkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_orderkey) AS line_count,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
)
SELECT ns.n_name AS nation_name,
       ss.s_name AS supplier_name,
       os.total_revenue,
       ss.total_parts,
       ss.total_available_qty,
       ss.avg_supply_cost,
       CASE 
           WHEN os.line_count > 10 THEN 'High Volume'
           ELSE 'Low Volume'
       END AS order_volume_category
FROM nation_hierarchy ns
LEFT JOIN supplier_summary ss ON ns.n_nationkey = ss.s_suppkey
LEFT JOIN order_summary os ON ss.s_suppkey = os.o_custkey
WHERE os.total_revenue IS NOT NULL
ORDER BY os.total_revenue DESC, ss.avg_supply_cost ASC
LIMIT 50;
