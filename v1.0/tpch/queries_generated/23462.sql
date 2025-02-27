WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_nationkey, 0 AS level, s.s_name
    FROM supplier s
    UNION ALL
    SELECT s1.s_suppkey, s1.s_nationkey, sh.level + 1, s1.s_name
    FROM supplier s1
    JOIN supplier_hierarchy sh ON s1.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
), part_supplier_summary AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
), nation_performance AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           COUNT(DISTINCT o.o_orderkey) FILTER (WHERE o.o_orderstatus = 'F') AS completed_orders
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_name
), ranked_parts AS (
    SELECT p.*, ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) as rn
    FROM part p
    WHERE p.p_size IS NOT NULL AND p.p_retailprice IS NOT NULL
)
SELECT n.n_name, 
       COALESCE(sp.total_avail_qty, 0) AS availability,
       rp.p_name,
       rp.p_retailprice,
       np.supplier_count,
       np.completed_orders,
       CASE 
           WHEN np.completed_orders > 10 THEN 'High Volume'
           ELSE 'Low Volume' 
       END AS order_volume_category,
       CASE 
           WHEN sp.avg_supply_cost < 50 THEN 'Low Cost'
           WHEN sp.avg_supply_cost BETWEEN 50 AND 100 THEN 'Moderate Cost'
           ELSE 'High Cost' 
       END AS supply_cost_category
FROM ranked_parts rp
LEFT JOIN part_supplier_summary sp ON rp.p_partkey = sp.ps_partkey
JOIN nation_performance np ON rp.p_partkey = (np.supplier_count % 100 + 1) -- Bizarre join condition
JOIN region r ON np.supplier_count = r.r_regionkey
LEFT JOIN (
    SELECT n.n_name, COUNT(*) AS nation_count 
    FROM nation n
    GROUP BY n.n_name
) AS nation_counts ON nation_counts.n_nationkey = np.supplier_count
WHERE rp.rn = 1 OR rp.rn % 5 = 0
ORDER BY n.n_name, rp.p_retailprice DESC
LIMIT 100;
