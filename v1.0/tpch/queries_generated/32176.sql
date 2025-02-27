WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_nationkey = 1
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
supplier_summary AS (
    SELECT s.s_nationkey, SUM(s.s_acctbal) AS total_acctbal, COUNT(*) AS supplier_count
    FROM supplier s
    GROUP BY s.s_nationkey
),
part_supplier AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    ps.p_name AS part_name,
    ps.total_supply_cost,
    ps.avg_supply_cost,
    ss.total_acctbal,
    ss.supplier_count,
    DENSE_RANK() OVER (PARTITION BY r.r_name ORDER BY ps.total_supply_cost DESC) AS rank_within_region
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN nation_hierarchy nh ON nh.n_regionkey = r.r_regionkey
LEFT JOIN part_supplier ps ON ps.p_partkey IN (
    SELECT ps_partkey 
    FROM partsupp 
    WHERE ps_availqty > 0
)
LEFT JOIN supplier_summary ss ON ss.s_nationkey = n.n_nationkey
WHERE (ss.total_acctbal IS NOT NULL OR ps.total_supply_cost > 1000)
  AND (ps.avg_supply_cost IS NOT NULL AND ps.avg_supply_cost < 50)
ORDER BY r.r_name, n.n_name, ps.total_supply_cost DESC;
