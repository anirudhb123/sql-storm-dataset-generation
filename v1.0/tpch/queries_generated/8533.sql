WITH RECURSIVE supplier_chain AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, ps.ps_partkey, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.n_nationkey, ps.ps_partkey, ps.ps_supplycost
    FROM supplier_chain sc
    JOIN supplier s ON s.s_nationkey = sc.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
),
region_summary AS (
    SELECT r.r_name, COUNT(DISTINCT sc.s_suppkey) AS supplier_count, SUM(sc.ps_supplycost) AS total_supply_cost
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier_chain sc ON n.n_nationkey = sc.s_nationkey
    GROUP BY r.r_name
)
SELECT r.r_name, rs.supplier_count, rs.total_supply_cost, AVG(o.o_totalprice) AS avg_order_total
FROM region r
JOIN region_summary rs ON r.r_name = rs.r_name
LEFT JOIN customer c ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
GROUP BY r.r_name, rs.supplier_count, rs.total_supply_cost
ORDER BY rs.total_supply_cost DESC, avg_order_total DESC;
